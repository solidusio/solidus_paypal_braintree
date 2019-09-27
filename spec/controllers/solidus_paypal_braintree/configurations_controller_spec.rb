require 'spec_helper'

describe SolidusPaypalBraintree::ConfigurationsController, type: :controller do
  routes { SolidusPaypalBraintree::Engine.routes }

  let!(:store_1) { create :store }
  let!(:store_2) { create :store }
  let(:store_1_config) { store_1.braintree_configuration }
  let(:store_2_config) { store_2.braintree_configuration }

  stub_authorization!

  describe "GET #list" do
    subject { get :list }

    it "assigns all store's configurations as @configurations" do
      subject
      expect(assigns(:configurations)).
        to eq [store_1.braintree_configuration, store_2.braintree_configuration]
    end

    it "renders the correct view" do
      expect(subject).to render_template :list
    end
  end

  describe "POST #update" do
    let(:paypal_button_color) { 'blue' }
    let(:configurations_params) do
      {
        configurations: {
          configuration_fields: {
            store_1_config.id.to_s => { paypal: true, apple_pay: true },
            store_2_config.id.to_s => {
              paypal: true,
              apple_pay: false,
              preferred_paypal_button_color: paypal_button_color
            }
          }
        }
      }
    end

    subject { post :update, params: configurations_params }

    context "with valid parameters" do
      it "updates the configuration" do
        expect { subject }.to change { store_1_config.reload.paypal }.
          from(false).to(true)
      end

      it "displays a success message to the user" do
        subject
        expect(flash[:success]).to eq "Successfully updated Braintree configurations."
      end

      it "displays all configurations" do
        expect(subject).to redirect_to action: :list
      end
    end

    context "with invalid parameters" do
      let(:paypal_button_color) { 'invalid-color'}

      it "displays an error message to the user" do
        subject
        expect(flash[:error]).to eq "An error occurred while updating Braintree configurations."
      end

      it "returns the user to the edit page" do
        expect(subject).to redirect_to action: :list
      end
    end
  end
end
