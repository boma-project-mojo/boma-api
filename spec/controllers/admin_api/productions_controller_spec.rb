require 'spec_helper'

describe AdminApi::V1::ProductionsController do

  before(:all) do
    @organisation = Organisation.create! name: "Mock Org"
    @festival = Festival.new name: "Mock Festival", organisation_id: @organisation.id, timezone: "Europe/London", bundle_id: "com.com.com", schedule_modal_type: "production", start_date: DateTime.now-1.week, end_date: DateTime.now+1.week 
    @festival.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
    @festival.save!

    @user = User.where({
      name: 'test',
      email: 'one@two.co.uk',
    }).first_or_initialize

    @user.password = 'abcdefgh'
    @user.password_confirmation = 'abcdefgh'

    @user.save!
    @user.add_role(:super_admin)

    @tag = AppData::Tag.create! name: "tag1", tag_type: "production", festival_id: @festival.id
    @venue = AppData::Venue.create! name: "venue1", venue_type: "performance", festival_id: @festival.id, remote_image_url: "https://boma-production-images.s3.amazonaws.com/test.png", description: "blah", list_order: 1
  end

  before do 
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(controller).to receive(:current_user).and_return(@user)
  end

  describe "POST create" do
    describe "with invalid params" do
      it "fails to create a new AppData::Production without a name" do
        request_payload = {
          data: {
            attributes:{
              short_description: "t", 
              description: "<p>t</p>", 
              external_link: nil, 
              video_link: nil, 
              ticket_link: nil, 
              image_name: nil, 
              image_base64: {}, 
              image_local: nil, 
              image_thumb: nil, 
              image_medium: nil, 
              truncated_description: nil, 
              truncated_short_description: nil, 
              aasm_state: nil, 
              is_owner: false, 
              can_update: false
            }, 
            type: "productions"
          }, 
          controller: "admin_api/v1/productions",
          action: "create",
          festival_id: @festival.id, 
          production: {
            data: {
              attributes: {
                short_description: "t", 
                description: "<p>t</p>", 
                external_link: nil, 
                video_link: nil, 
                ticket_link: nil, 
                image_name: nil, 
                image_base64: {}, 
                image_local: nil, 
                image_thumb: nil, 
                image_medium: nil, 
                truncated_description: nil, 
                truncated_short_description: nil, 
                aasm_state: nil, 
                is_owner: false, 
                can_update: false
              }, 
              type: "productions"
            }
          }
        }

        post :create, params: request_payload
        expect(response).to have_http_status(:unprocessable_entity)
      end

      # validates :short_description, :length => {maximum: 500, message: "can't be more than 250 characters"}
      it "fails to create a new AppData::Production with a short_description longer than 500 characters" do
        request_payload = {
          data: {
            attributes:{
              name: "name",
              short_description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi vitae faucibus magna. Proin convallis leo lorem. Integer blandit sollicitudin elit, ac sagittis nibh. Aenean felis nibh, ultrices non rhoncus vitae, porta vitae metus. Nunc in luctus lacus. Integer consectetur condimentum leo ut accumsan. Praesent in auctor augue. Nam diam dui, egestas at porttitor et, laoreet vitae enim. Donec aliquet ex sed metus dapibus, in dictum orci eleifend. Nam suscipit massa tempor velit aliquam mattis metus hello.", 
              description: "<p>t</p>", 
              external_link: nil, 
              video_link: nil, 
              ticket_link: nil, 
              image_name: nil, 
              image_base64: {}, 
              image_local: nil, 
              image_thumb: nil, 
              image_medium: nil, 
              truncated_description: nil, 
              truncated_short_description: nil, 
              aasm_state: nil, 
              is_owner: false, 
              can_update: false
            }, 
            type: "productions"
          }, 
          controller: "admin_api/v1/productions",
          action: "create",
          festival_id: @festival.id, 
          production: {
            data: {
              attributes: {
                name: "name",
                short_description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi vitae faucibus magna. Proin convallis leo lorem. Integer blandit sollicitudin elit, ac sagittis nibh. Aenean felis nibh, ultrices non rhoncus vitae, porta vitae metus. Nunc in luctus lacus. Integer consectetur condimentum leo ut accumsan. Praesent in auctor augue. Nam diam dui, egestas at porttitor et, laoreet vitae enim. Donec aliquet ex sed metus dapibus, in dictum orci eleifend. Nam suscipit massa tempor velit aliquam mattis metus hello.", 
                description: "<p>t</p>", 
                external_link: nil, 
                video_link: nil, 
                ticket_link: nil, 
                image_name: nil, 
                image_base64: {}, 
                image_local: nil, 
                image_thumb: nil, 
                image_medium: nil, 
                truncated_description: nil, 
                truncated_short_description: nil, 
                aasm_state: nil, 
                is_owner: false, 
                can_update: false
              }, 
              type: "productions"
            }
          }
        }

        post :create, params: request_payload
        expect(response).to have_http_status(:unprocessable_entity)
      end

      # validates :external_link, link: true, allow_blank: true
      it "succeeds to create a new AppData::Production if external_link is blank" do
        request_payload = {
          data: {
            attributes:{
              name: "name",
              short_description: "t", 
              description: "<p>t</p>", 
              external_link: nil, 
              video_link: nil, 
              ticket_link: nil, 
              image_name: nil, 
              image_base64: {}, 
              image_local: nil, 
              image_thumb: nil, 
              image_medium: nil, 
              truncated_description: nil, 
              truncated_short_description: nil, 
              aasm_state: nil, 
              is_owner: false, 
              can_update: false
            }, 
            type: "productions"
          }, 
          controller: "admin_api/v1/productions",
          action: "create",
          festival_id: @festival.id, 
          production: {
            data: {
              attributes: {
                name: "name",
                short_description: "t", 
                description: "<p>t</p>", 
                external_link: nil, 
                video_link: nil, 
                ticket_link: nil, 
                image_name: nil, 
                image_base64: {}, 
                image_local: nil, 
                image_thumb: nil, 
                image_medium: nil, 
                truncated_description: nil, 
                truncated_short_description: nil, 
                aasm_state: nil, 
                is_owner: false, 
                can_update: false
              }, 
              type: "productions"
            }
          }
        }

        post :create, params: request_payload
        expect(response).to have_http_status(:success)
      end
      it "fails to create a new AppData::Production with a link if the link is invalid" do
        request_payload = {
          data: {
            attributes:{
              name: "name",
              short_description: "t", 
              description: "<p>t</p>", 
              external_link: "invalidlink", 
              video_link: nil, 
              ticket_link: nil, 
              image_name: nil, 
              image_base64: {}, 
              image_local: nil, 
              image_thumb: nil, 
              image_medium: nil, 
              truncated_description: nil, 
              truncated_short_description: nil, 
              aasm_state: nil, 
              is_owner: false, 
              can_update: false
            }, 
            type: "productions"
          }, 
          controller: "admin_api/v1/productions",
          action: "create",
          festival_id: @festival.id, 
          production: {
            data: {
              attributes: {
                name: "name",
                short_description: "t", 
                description: "<p>t</p>", 
                external_link: "invalidlink", 
                video_link: nil, 
                ticket_link: nil, 
                image_name: nil, 
                image_base64: {}, 
                image_local: nil, 
                image_thumb: nil, 
                image_medium: nil, 
                truncated_description: nil, 
                truncated_short_description: nil, 
                aasm_state: nil, 
                is_owner: false, 
                can_update: false
              }, 
              type: "productions"
            }
          }
        }

        post :create, params: request_payload
        expect(response).to have_http_status(:success)
      end

      # validate :has_image, if: -> {
      #   (is_checking_app_validity || 
      #   publishing? || 
      #   published?) && require_production_images? 
      # }
      it "succeeds in publishing an AppData::Production without a valid image when the image is not required" do
        @festival2 = Festival.new name: "Mock Festival", organisation_id: @organisation.id, timezone: "Europe/London", bundle_id: "com.com.com", schedule_modal_type: "production", start_date: DateTime.now-1.week, end_date: DateTime.now+1.week, require_production_images: false
        @festival2.remote_image_url = "https://boma-production-images.s3.amazonaws.com/test.png"
        @festival2.save!

        request_payload = {
          data: {
            attributes:{
              name: "name",
              short_description: "t", 
              description: "<p>t</p>", 
              external_link: nil, 
              video_link: nil, 
              ticket_link: nil, 
              image_name: nil, 
              image_base64: {}, 
              image_local: nil, 
              image_thumb: nil, 
              image_medium: nil, 
              truncated_description: nil, 
              truncated_short_description: nil, 
              aasm_state: nil, 
              is_owner: false, 
              can_update: false
            }, 
            type: "productions"
          }, 
          controller: "admin_api/v1/productions",
          action: "create",
          festival_id: @festival2.id, 
          production: {
            data: {
              attributes: {
                name: "name",
                short_description: "t", 
                description: "<p>t</p>", 
                external_link: nil, 
                video_link: nil, 
                ticket_link: nil, 
                image_name: nil, 
                image_base64: {}, 
                image_local: nil, 
                image_thumb: nil, 
                image_medium: nil, 
                truncated_description: nil, 
                truncated_short_description: nil, 
                aasm_state: nil, 
                is_owner: false, 
                can_update: false
              }, 
              type: "productions"
            }
          }
        }

        response = post :create, params: request_payload

        production = @festival2.productions.find(JSON.parse(response.body)['data']['id'])
        production.lock!
        production.publish!

        expect { production.published? }.equal?(true)
      end

      it "fails to publish an AppData::Production without a valid image" do
        request_payload = {
          data: {
            attributes:{
              name: "name",
              short_description: "t", 
              description: "<p>t</p>", 
              external_link: nil, 
              video_link: nil, 
              ticket_link: nil, 
              image_name: nil, 
              image_base64: {}, 
              image_local: nil, 
              image_thumb: nil, 
              image_medium: nil, 
              truncated_description: nil, 
              truncated_short_description: nil, 
              aasm_state: nil, 
              is_owner: false, 
              can_update: false
            }, 
            type: "productions"
          }, 
          controller: "admin_api/v1/productions",
          action: "create",
          festival_id: @festival.id, 
          production: {
            data: {
              attributes: {
                name: "name",
                short_description: "t", 
                description: "<p>t</p>", 
                external_link: nil, 
                video_link: nil, 
                ticket_link: nil, 
                image_name: nil, 
                image_base64: {}, 
                image_local: nil, 
                image_thumb: nil, 
                image_medium: nil, 
                truncated_description: nil, 
                truncated_short_description: nil, 
                aasm_state: nil, 
                is_owner: false, 
                can_update: false
              }, 
              type: "productions"
            }
          }
        }

        response = post :create, params: request_payload
        
        production = @festival.productions.find(JSON.parse(response.body)['data']['id'])
        production.lock!

        expect { production.publish! }.to raise_error(an_instance_of(ActiveRecord::RecordInvalid).and having_attributes(message: "Validation failed: Image must be added"))
      end

      # validates :description, presence: {message: "can't be blank"}, if: -> {
      #   is_checking_app_validity || 
      #   publishing? || 
      #   published?
      # }
      it "fails to publish an AppData::Production without a valid description" do
        request_payload = {
          data: {
            attributes:{
              name: "name",
              short_description: "t", 
              description: "<p></p>", 
              external_link: nil, 
              video_link: nil, 
              ticket_link: nil, 
              image_name: nil, 
              image_base64: {"name":"test.jpg","data":"data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAASABIAAD/4QBkRXhpZgAATU0AKgAAAAgABAEGAAMAAAABAAIAAAESAAMAAAABAAEAAAEoAAMAAAABAAIAAIdpAAQAAAABAAAAPgAAAAAAAqACAAQAAAABAAAACqADAAQAAAABAAAADgAAAAD/4QkhaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiLz4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8P3hwYWNrZXQgZW5kPSJ3Ij8+AP/tADhQaG90b3Nob3AgMy4wADhCSU0EBAAAAAAAADhCSU0EJQAAAAAAENQdjNmPALIE6YAJmOz4Qn7/4gIYSUNDX1BST0ZJTEUAAQEAAAIIYXBwbAQAAABtbnRyUkdCIFhZWiAH5gAKAAoACQAQAAZhY3NwQVBQTAAAAABBUFBMAAAAAAAAAAAAAAAAAAAAAAAA9tYAAQAAAADTLWFwcGxz59wUi9QYXDTUE8IATQlHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAApkZXNjAAAA/AAAADBjcHJ0AAABLAAAAFB3dHB0AAABfAAAABRyWFlaAAABkAAAABRnWFlaAAABpAAAABRiWFlaAAABuAAAABRyVFJDAAABzAAAABBjaGFkAAAB3AAAACxiVFJDAAABzAAAABBnVFJDAAABzAAAABBtbHVjAAAAAAAAAAEAAAAMZW5VUwAAABQAAAAcAFMAeQBuAGMATQBhAHMAdABlAHJtbHVjAAAAAAAAAAEAAAAMZW5VUwAAADQAAAAcAEMAbwBwAHkAcgBpAGcAaAB0ACAAQQBwAHAAbABlACAASQBuAGMALgAsACAAMgAwADIAMlhZWiAAAAAAAAD21gABAAAAANMtWFlaIAAAAAAAAHlbAAA+ZwAAAYVYWVogAAAAAAAAWUMAAK58AAAXr1hZWiAAAAAAAAAkNwAAEx0AALn5cGFyYQAAAAAAAAAAAAH2BHNmMzIAAAAAAAEMcgAABfj///MdAAAHugAA/XL///ud///9pAAAA9kAAMBx/8AAEQgADgAKAwEiAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/bAEMAAQEBAQEBAgEBAgMCAgIDBAMDAwMEBgQEBAQEBgcGBgYGBgYHBwcHBwcHBwgICAgICAkJCQkJCwsLCwsLCwsLC//bAEMBAgICAwMDBQMDBQsIBggLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLC//dAAQAAf/aAAwDAQACEQMRAD8A/wA/+iiigD//2Q=="}, 
              image_local: nil, 
              image_thumb: nil, 
              image_medium: nil, 
              truncated_description: nil, 
              truncated_short_description: nil, 
              aasm_state: nil, 
              is_owner: false, 
              can_update: false
            }, 
            type: "productions"
          }, 
          controller: "admin_api/v1/productions",
          action: "create",
          festival_id: @festival.id, 
          production: {
            data: {
              attributes: {
                name: "name",
                short_description: "t", 
                description: nil, 
                external_link: nil, 
                video_link: nil, 
                ticket_link: nil, 
                image_name: nil, 
                image_base64: {"name":"test.jpg","data":"data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAASABIAAD/4QBkRXhpZgAATU0AKgAAAAgABAEGAAMAAAABAAIAAAESAAMAAAABAAEAAAEoAAMAAAABAAIAAIdpAAQAAAABAAAAPgAAAAAAAqACAAQAAAABAAAACqADAAQAAAABAAAADgAAAAD/4QkhaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiLz4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8P3hwYWNrZXQgZW5kPSJ3Ij8+AP/tADhQaG90b3Nob3AgMy4wADhCSU0EBAAAAAAAADhCSU0EJQAAAAAAENQdjNmPALIE6YAJmOz4Qn7/4gIYSUNDX1BST0ZJTEUAAQEAAAIIYXBwbAQAAABtbnRyUkdCIFhZWiAH5gAKAAoACQAQAAZhY3NwQVBQTAAAAABBUFBMAAAAAAAAAAAAAAAAAAAAAAAA9tYAAQAAAADTLWFwcGxz59wUi9QYXDTUE8IATQlHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAApkZXNjAAAA/AAAADBjcHJ0AAABLAAAAFB3dHB0AAABfAAAABRyWFlaAAABkAAAABRnWFlaAAABpAAAABRiWFlaAAABuAAAABRyVFJDAAABzAAAABBjaGFkAAAB3AAAACxiVFJDAAABzAAAABBnVFJDAAABzAAAABBtbHVjAAAAAAAAAAEAAAAMZW5VUwAAABQAAAAcAFMAeQBuAGMATQBhAHMAdABlAHJtbHVjAAAAAAAAAAEAAAAMZW5VUwAAADQAAAAcAEMAbwBwAHkAcgBpAGcAaAB0ACAAQQBwAHAAbABlACAASQBuAGMALgAsACAAMgAwADIAMlhZWiAAAAAAAAD21gABAAAAANMtWFlaIAAAAAAAAHlbAAA+ZwAAAYVYWVogAAAAAAAAWUMAAK58AAAXr1hZWiAAAAAAAAAkNwAAEx0AALn5cGFyYQAAAAAAAAAAAAH2BHNmMzIAAAAAAAEMcgAABfj///MdAAAHugAA/XL///ud///9pAAAA9kAAMBx/8AAEQgADgAKAwEiAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/bAEMAAQEBAQEBAgEBAgMCAgIDBAMDAwMEBgQEBAQEBgcGBgYGBgYHBwcHBwcHBwgICAgICAkJCQkJCwsLCwsLCwsLC//bAEMBAgICAwMDBQMDBQsIBggLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLC//dAAQAAf/aAAwDAQACEQMRAD8A/wA/+iiigD//2Q=="}, 
                image_local: nil, 
                image_thumb: nil, 
                image_medium: nil, 
                truncated_description: nil, 
                truncated_short_description: nil, 
                aasm_state: nil, 
                is_owner: false, 
                can_update: false
              }, 
              type: "productions"
            }
          }
        }

        response = post :create, params: request_payload
        
        production = @festival.productions.find(JSON.parse(response.body)['data']['id'])
        production.lock!

        expect { production.publish! }.to raise_error(an_instance_of(ActiveRecord::RecordInvalid).and having_attributes(message: "Validation failed: Description can't be blank"))
      end

      # validate :has_valid_events, if: -> {
      #   is_checking_app_validity || 
      #   publishing? || 
      #   published?
      # }
      it "fails to publish an AppData::Production without valid events" do
        request_payload = {
          data: {
            attributes:{
              name: "name",
              short_description: "t", 
              description: "<p>blah</p>", 
              external_link: nil, 
              video_link: nil, 
              ticket_link: nil, 
              image_name: nil, 
              image_base64: {"name":"test.jpg","data":"data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAASABIAAD/4QBkRXhpZgAATU0AKgAAAAgABAEGAAMAAAABAAIAAAESAAMAAAABAAEAAAEoAAMAAAABAAIAAIdpAAQAAAABAAAAPgAAAAAAAqACAAQAAAABAAAACqADAAQAAAABAAAADgAAAAD/4QkhaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiLz4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8P3hwYWNrZXQgZW5kPSJ3Ij8+AP/tADhQaG90b3Nob3AgMy4wADhCSU0EBAAAAAAAADhCSU0EJQAAAAAAENQdjNmPALIE6YAJmOz4Qn7/4gIYSUNDX1BST0ZJTEUAAQEAAAIIYXBwbAQAAABtbnRyUkdCIFhZWiAH5gAKAAoACQAQAAZhY3NwQVBQTAAAAABBUFBMAAAAAAAAAAAAAAAAAAAAAAAA9tYAAQAAAADTLWFwcGxz59wUi9QYXDTUE8IATQlHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAApkZXNjAAAA/AAAADBjcHJ0AAABLAAAAFB3dHB0AAABfAAAABRyWFlaAAABkAAAABRnWFlaAAABpAAAABRiWFlaAAABuAAAABRyVFJDAAABzAAAABBjaGFkAAAB3AAAACxiVFJDAAABzAAAABBnVFJDAAABzAAAABBtbHVjAAAAAAAAAAEAAAAMZW5VUwAAABQAAAAcAFMAeQBuAGMATQBhAHMAdABlAHJtbHVjAAAAAAAAAAEAAAAMZW5VUwAAADQAAAAcAEMAbwBwAHkAcgBpAGcAaAB0ACAAQQBwAHAAbABlACAASQBuAGMALgAsACAAMgAwADIAMlhZWiAAAAAAAAD21gABAAAAANMtWFlaIAAAAAAAAHlbAAA+ZwAAAYVYWVogAAAAAAAAWUMAAK58AAAXr1hZWiAAAAAAAAAkNwAAEx0AALn5cGFyYQAAAAAAAAAAAAH2BHNmMzIAAAAAAAEMcgAABfj///MdAAAHugAA/XL///ud///9pAAAA9kAAMBx/8AAEQgADgAKAwEiAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/bAEMAAQEBAQEBAgEBAgMCAgIDBAMDAwMEBgQEBAQEBgcGBgYGBgYHBwcHBwcHBwgICAgICAkJCQkJCwsLCwsLCwsLC//bAEMBAgICAwMDBQMDBQsIBggLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLC//dAAQAAf/aAAwDAQACEQMRAD8A/wA/+iiigD//2Q=="}, 
              image_local: nil, 
              image_thumb: nil, 
              image_medium: nil, 
              truncated_description: nil, 
              truncated_short_description: nil, 
              aasm_state: nil, 
              is_owner: false, 
              can_update: false
            }, 
            type: "productions"
          }, 
          controller: "admin_api/v1/productions",
          action: "create",
          festival_id: @festival.id, 
          production: {
            data: {
              attributes: {
                name: "name",
                short_description: "t", 
                description: "<p>blah</p>", 
                external_link: nil, 
                video_link: nil, 
                ticket_link: nil, 
                image_name: nil, 
                image_base64: {"name":"test.jpg","data":"data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAASABIAAD/4QBkRXhpZgAATU0AKgAAAAgABAEGAAMAAAABAAIAAAESAAMAAAABAAEAAAEoAAMAAAABAAIAAIdpAAQAAAABAAAAPgAAAAAAAqACAAQAAAABAAAACqADAAQAAAABAAAADgAAAAD/4QkhaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wLwA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIenJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtZXRhIHhtbG5zOng9ImFkb2JlOm5zOm1ldGEvIiB4OnhtcHRrPSJYTVAgQ29yZSA2LjAuMCI+IDxyZGY6UkRGIHhtbG5zOnJkZj0iaHR0cDovL3d3dy53My5vcmcvMTk5OS8wMi8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmRmOmFib3V0PSIiLz4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA8P3hwYWNrZXQgZW5kPSJ3Ij8+AP/tADhQaG90b3Nob3AgMy4wADhCSU0EBAAAAAAAADhCSU0EJQAAAAAAENQdjNmPALIE6YAJmOz4Qn7/4gIYSUNDX1BST0ZJTEUAAQEAAAIIYXBwbAQAAABtbnRyUkdCIFhZWiAH5gAKAAoACQAQAAZhY3NwQVBQTAAAAABBUFBMAAAAAAAAAAAAAAAAAAAAAAAA9tYAAQAAAADTLWFwcGxz59wUi9QYXDTUE8IATQlHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAApkZXNjAAAA/AAAADBjcHJ0AAABLAAAAFB3dHB0AAABfAAAABRyWFlaAAABkAAAABRnWFlaAAABpAAAABRiWFlaAAABuAAAABRyVFJDAAABzAAAABBjaGFkAAAB3AAAACxiVFJDAAABzAAAABBnVFJDAAABzAAAABBtbHVjAAAAAAAAAAEAAAAMZW5VUwAAABQAAAAcAFMAeQBuAGMATQBhAHMAdABlAHJtbHVjAAAAAAAAAAEAAAAMZW5VUwAAADQAAAAcAEMAbwBwAHkAcgBpAGcAaAB0ACAAQQBwAHAAbABlACAASQBuAGMALgAsACAAMgAwADIAMlhZWiAAAAAAAAD21gABAAAAANMtWFlaIAAAAAAAAHlbAAA+ZwAAAYVYWVogAAAAAAAAWUMAAK58AAAXr1hZWiAAAAAAAAAkNwAAEx0AALn5cGFyYQAAAAAAAAAAAAH2BHNmMzIAAAAAAAEMcgAABfj///MdAAAHugAA/XL///ud///9pAAAA9kAAMBx/8AAEQgADgAKAwEiAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/bAEMAAQEBAQEBAgEBAgMCAgIDBAMDAwMEBgQEBAQEBgcGBgYGBgYHBwcHBwcHBwgICAgICAkJCQkJCwsLCwsLCwsLC//bAEMBAgICAwMDBQMDBQsIBggLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLC//dAAQAAf/aAAwDAQACEQMRAD8A/wA/+iiigD//2Q=="}, 
                image_local: nil, 
                image_thumb: nil, 
                image_medium: nil, 
                truncated_description: nil, 
                truncated_short_description: nil, 
                aasm_state: nil, 
                is_owner: false, 
                can_update: false
              }, 
              type: "productions"
            }
          }
        }

        response = post :create, params: request_payload
        
        production = @festival.productions.find(JSON.parse(response.body)['data']['id'])
        
        event = production.events.create! start_time: nil, end_time: @festival.start_date+1.day+2.hours, venue: @venue, festival: @festival, productions: [production]

        production.lock!

        expect { production.publish! }.to raise_error(an_instance_of(ActiveRecord::RecordInvalid).and having_attributes(message: "Validation failed: Events Start time can't be blank (ID: #{event.id})"))
      end
    end
  end

end