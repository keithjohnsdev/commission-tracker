class DashboardsController < ApplicationController
  def show
    @agency   = Agency.find(params[:agency_id])
    @bookings = @agency.bookings.includes(advisor: :agency)   # eager-load → no N+1
  end
end
