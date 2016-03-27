require "test_helper"
include Warden::Test::Helpers

class UserLockable < ActionDispatch::IntegrationTest
  it "should lock after 10 tries on user" do

    @user = FactoryGirl.create(:user)

    (1..8).each do |n|
      login(@user.email, "trololololo")
      page.must_have_content I18n.t('devise.failure.not_found_in_database')
    end

    login(@user.email, "trololololo")
    page.must_have_content I18n.t('devise.failure.last_attempt')

    login(@user.email, "trololololo")
    page.must_have_content I18n.t('devise.failure.locked')
  end

  private

  def login(username, password)
    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "trololololo" 
    click_button "Acceder"

  end

end