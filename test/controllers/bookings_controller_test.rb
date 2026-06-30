require "test_helper"

class BookingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @booking = bookings(:one)
  end

  test "should get index" do
    get bookings_url
    assert_response :success
  end

  test "should get new" do
    get new_booking_url
    assert_response :success
  end

  test "should create booking" do
    assert_difference("Booking.count") do
      post bookings_url, params: { booking: { advisor_id: @booking.advisor_id, commission_rate: @booking.commission_rate, commission_received: @booking.commission_received, status: @booking.status, supplier_name: @booking.supplier_name, total_amount: @booking.total_amount, travel_date: @booking.travel_date, trip_name: @booking.trip_name } }
    end

    assert_redirected_to bookings_url
  end

  test "should show booking" do
    get booking_url(@booking)
    assert_response :success
  end

  test "should get edit" do
    get edit_booking_url(@booking)
    assert_response :success
  end

  test "should update booking" do
    patch booking_url(@booking), params: { booking: { advisor_id: @booking.advisor_id, commission_rate: @booking.commission_rate, commission_received: @booking.commission_received, status: @booking.status, supplier_name: @booking.supplier_name, total_amount: @booking.total_amount, travel_date: @booking.travel_date, trip_name: @booking.trip_name } }
    assert_redirected_to booking_url(@booking)
  end

  test "should destroy booking" do
    assert_difference("Booking.count", -1) do
      delete booking_url(@booking)
    end

    assert_redirected_to bookings_url
  end
end
