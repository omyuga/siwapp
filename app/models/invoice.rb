class Invoice < Common
  # Relations
  belongs_to :recurring_invoice
  belongs_to :template
  has_many :payments, dependent: :destroy
  accepts_nested_attributes_for :payments, :reject_if => :all_blank, :allow_destroy => true

  # Validation
  validates :series, presence: true
  validates :issue_date, presence: true
  validates :number, numericality: { only_integer: true, allow_nil: true }

  # Events
  around_save :ensure_invoice_number, if: :needs_invoice_number
  after_update :purge_payments
  after_save :update_paid

  scope :with_status, ->(status) {
    return nil if status.empty?
    status = status.to_sym
    case status
    when :draft
      where(draft: true)
    when :paid
      where(draft: false, paid: true)
    when :pending
      where(draft: false, paid: false).where("due_date >= ?", Date.today)
    when :overdue
      where(draft: false, paid: false).where("due_date < ?", Date.today)
    end
  }

  # Invoices belonging to certain recurring_invoice
  scope :belonging_to, -> (r_id) {where recurring_invoice_id: r_id}


protected

  # Declare scopes for search
  def self.ransackable_scopes(auth_object = nil)
    super + [:with_status]
  end

public

  def self.status_collection
    [["Draft", :draft], ["Paid", :paid], ["Pending", :pending], ["Overdue", :overdue]]
  end

  # Public: Get a string representation of this object
  #
  # Returns a string.
  def to_s
    label = draft ? '[draft]' : number? ? number: "(#{series.next_number})"
    "#{series.value}#{label}"
  end

  # Public: Returns the status of the invoice based on certain conditions.
  #
  # Returns a symbol.
  def get_status
    if draft
      :draft
    elsif paid
      :paid
    elsif due_date
      if due_date > Date.today
        :pending
      else
        :overdue
      end
    else
      # An invoice without a due date can't be overdue
      :pending
    end
  end

  # Returns the invoice template if set, and the default otherwise
  def get_template
    if self.template
      return self.template
    end
    Template.find_by(default: true)
  end

  # Public: Returns the amount that has not been already paid.
  #
  # Returns a double.
  def unpaid_amount
    gross_amount - paid_amount
  end

  # Public: Creates the payment to set as paid the invoice.
  #
  def set_paid
    if unpaid_amount > 0 and not paid
      payment = Payment.create(
          invoice_id: self.id,
          date: Date.today,
          amount: unpaid_amount)
      self.save
    end
  end

  # Public: Check the payments and update the paid and
  # paid_amount fields
  #
  def check_paid
    self.paid_amount = 0
    self.paid = false
    payments.each do |payment|
      self.paid_amount += payment.amount
    end
    
    if self.paid_amount - self.gross_amount >= 0
      self.paid = true
    end
  end

  # Public: After saving check the payments and update the paid and
  # paid_amount fields
  #
  def update_paid
    self.check_paid
    # Use update_columns to skip more callbacks
    self.update_columns(paid: self.paid, paid_amount: self.paid_amount)
  end

  # Public: Calculate totals for this invoice by iterating items and payments.
  #
  # Returns nothing.
  def set_amounts
    super
    self.check_paid
    paid_amount_will_change!
  end

  # Sends email to user with the invoice attached
  def send_email
    # There is a deliver_later method which we could use
    InvoiceMailer.email_invoice(self).deliver_now
    self.sent_by_email = true
    self.save
  end

  # Returns the pdf file
  def pdf(html)
    WickedPdf.new.pdf_from_string(html,
      margin: {:top => 0, :bottom => 0, :left => 0, :right => 0})
  end

  protected

    # Protected: Decide whether this invoice needs an invoice number. It's true
    # when the invoice is not a draft and has no invoice number.
    #
    # Returns a boolean.
    def needs_invoice_number
      !draft and number.nil?
    end

    # Protected: Sets the invoice number to the series next number and updates
    # the series by incrementing the next_number counter.
    #
    # Returns nothing.
    def ensure_invoice_number
      self.number = series.next_number
      yield
      series.update_attribute :next_number, number + 1
    end

    # make sure every soft-deleted payment is really deleted
    def purge_payments
      payments.only_deleted.delete_all
    end

end
