class RecurringInvoicesController < CommonsController

  def generate
    # Generates pending invoices up to today
    for r in RecurringInvoice.with_pending_invoices
      r.generate_pending_invoices
    end
    redirect_to invoices_url
  end

  def index
    @has_pendings = (not RecurringInvoice.with_pending_invoices.empty?)
    super
  end

  # DELETE
  # bulk deletes selected elements on list
  def remove
    ids = params["#{model.name.underscore}_ids"]
    if ids.is_a?(Array) && ids.length > 0
      model.where(id: params["#{model.name.underscore}_ids"]).destroy_all
      flash[:info] = "Successfully deleted #{ids.length} #{type_label}"
    end
    redirect_to sti_path(@type)
  end

  # GET /recurring_invoices/chart_data.json
  # Returns a json with dates as keys and sums of the invoices
  # as values
  def chart_data
    # date_from = (params[:q].nil? or params[:q][:issue_date_gteq].empty?) ? 30.days.ago.to_date : Date.parse(params[:q][:issue_date_gteq])
    # date_to = (params[:q].nil? or params[:q][:issue_date_lteq].empty?) ? Date.today : Date.parse(params[:q][:issue_date_lteq])

    # scope = @search.result(distinct: true)
    # scope = scope.tagged_with(params[:tags].split(/\s*,\s*/)) if params[:tags].present?
    # scope = scope.select('issue_date, sum(gross_amount) as total').where(active: true).group('issue_date')

    # build all keys with 0 values for all
    @date_totals = {}

    # (date_from..date_to).each do |day|
    #   @date_totals[day.to_formatted_s(:db)] = 0
    # end

    # scope.each do |inv|
    #   @date_totals[inv.issue_date.to_formatted_s(:db)] = inv.total
    # end

    render
  end


  protected

  def configure_search
    super
    @search_filters = true
  end

  def set_listing(instances)
    @recurring_invoices = instances
  end

  def set_instance(instance)
    @recurring_invoice = instance
  end

  def get_instance
    @recurring_invoice
  end

  def recurring_invoice_params
    [
      :series_id,

      :customer_id,
      :identification,
      :name,
      :email,
      :contact_person,
      :invoicing_address,
      :shipping_address,

      :status,
      :days_to_due,
      :draft,
      :starting_date,
      :finishing_date,
      :period,
      :period_type,
      :max_occurrences,
      :sent_by_email,

      :tag_list,

      items_attributes: [
        :id,
        :description,
        :quantity,
        :unitary_cost,
        :discount,
        {:tax_ids => []},
        :_destroy
      ]
    ]
  end

end
