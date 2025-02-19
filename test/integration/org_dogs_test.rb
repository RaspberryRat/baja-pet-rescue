require "test_helper"

class OrgDogsTest < ActionDispatch::IntegrationTest

  setup do
    @dog = dogs(:dog_one)
    @org_id = users(:user_two).staff_account.organization_id
  end

  teardown do
    :after_teardown
  end

  test "adopter user cannot access org dogs index" do
    sign_in users(:user_one)
    get "/dogs/new"
    assert_response :redirect
    follow_redirect!
    assert_equal '/', path
    assert_equal 'Unauthorized action.', flash[:alert]
  end

  test "unverified staff cannot access org dogs index" do
    sign_in users(:user_three)
    get "/dogs/new"
    assert_response :redirect
    follow_redirect!
    assert_equal '/', path
    assert_equal 'Unauthorized action.', flash[:alert]
  end

  test "unverified staff cannot post to org dogs" do
    sign_in users(:user_three)

    post "/dogs",
      params: { dog:
        {
          organization_id: "#{organizations(:organization_one).id}",
          name: 'TestDog',
          age: '3',
          sex: 'Female',
          breed: 'mix',
          size: 'Medium (22-57 lb)',
          description: 'A lovely little pooch this one.',
          append_images: ['']
        }
      }

    assert_response :redirect
    follow_redirect!
    assert_equal 'Unauthorized action.', flash[:alert]
  end

  test "verified staff can access org dogs index" do
    sign_in users(:user_two)
    get "/dogs/new"
    assert_response :success
  end

  test "verified staff can access dog/new" do
    sign_in users(:user_two)
    get "/dogs/new"
    assert_response :success
  end

  test "verified staff can create a new dog post" do
    sign_in users(:user_two)

    post "/dogs",
      params: { dog:
        {
          organization_id: "#{organizations(:organization_one).id}",
          name: 'TestDog',
          age: '3',
          sex: 'Female',
          breed: 'mix',
          size: 'Medium (22-57 lb)',
          description: 'A lovely little pooch this one.',
          append_images: [''] 
        }
      }

    assert_response :redirect
    follow_redirect!
    assert_equal 'Dog saved successfully.', flash[:notice]
    assert_select "h1", "Our dogs"
  end

  test "verified staff can edit a dog post" do 
    sign_in users(:user_two)

    patch "/dogs/#{@dog.id}",
      params: { dog:
        {
          organization_id: "#{organizations(:organization_one).id}",
          name: 'TestDog',
          age: '7',
          sex: 'Female',
          breed: 'mix',
          size: 'Medium (22-57 lb)',
          description: 'A lovely little pooch this one.',
          append_images: [''] 
        }
      }

    assert_response :redirect
    follow_redirect!
    assert_equal 'Dog updated successfully.', flash[:notice]
    assert_select "h1", "TestDog"
  end

  test "verified staff can pause dog and pause reason is selected in dropdown" do 
    sign_in users(:user_two)

    patch "/dogs/#{@dog.id}",
      params: { dog:
        {
          organization_id: "#{organizations(:organization_one).id}",
          name: 'TestDog',
          age: '7',
          sex: 'Female',
          breed: 'mix',
          size: 'Medium (22-57 lb)',
          description: 'A lovely little pooch this one.',
          application_paused: true,
          pause_reason: 'paused_until_further_notice'
        }
      }

    assert_response :redirect
    follow_redirect!
    assert_equal 'Dog updated successfully.', flash[:notice]
    @dog.reload
    assert_equal @dog.pause_reason, 'paused_until_further_notice'
    assert_equal @dog.application_paused, true
    assert_select 'form' do
      assert_select 'option[selected="selected"]', 'Paused Until Further Notice'
    end
  end

  test "verified staff can unpause a paused dog and the pause reason reverts to not paused" do
    sign_in users(:user_two)

    patch "/dogs/#{@dog.id}",
      params: { dog:
        {
          organization_id: "#{organizations(:organization_one).id}",
          name: 'TestDog',
          age: '7',
          sex: 'Female',
          breed: 'mix',
          size: 'Medium (22-57 lb)',
          description: 'A lovely little pooch this one.',
          application_paused: 'true',
          pause_reason: 'paused_until_further_notice'
        }
      }

    assert_response :redirect
    follow_redirect!
    assert_equal 'Dog updated successfully.', flash[:notice]
    @dog.reload
    assert_equal @dog.application_paused, true
    assert_equal @dog.pause_reason, 'paused_until_further_notice'

    patch "/dogs/#{@dog.id}",
      params: { dog:
        {
          organization_id: "#{organizations(:organization_one).id}",
          name: 'TestDog',
          age: '7',
          sex: 'Female',
          breed: 'mix',
          size: 'Medium (22-57 lb)',
          description: 'A lovely little pooch this one.',
          application_paused: 'false',
          pause_reason: 'paused_until_further_notice'
        }
      }

    assert_response :redirect
    follow_redirect!
    assert_equal 'Dog updated successfully.', flash[:notice]
    @dog.reload
    assert_equal @dog.application_paused, false
    assert_equal @dog.pause_reason, 'not_paused'
  end

  test "verified staff can upload multiple images and delete one of the images" do
    sign_in users(:user_two)

    patch "/dogs/#{@dog.id}",
      params: { dog:
        {
          organization_id: "#{organizations(:organization_one).id}",
          name: 'TestDog',
          age: '7',
          sex: 'Female',
          breed: 'mix',
          size: 'Medium (22-57 lb)',
          description: 'A lovely little pooch this one.',
          append_images:
          [
            fixture_file_upload("test.png", "image/png"),
            fixture_file_upload("test2.png", "image/png")
          ]
        }
      }

    assert_equal @dog.images_attachments.length, 2
    images = @dog.images_attachments

    delete "/attachments/#{images[1].id}/purge",
      params: { id: "#{images[1].id}" },
      headers: { "HTTP_REFERER" => "http://www.example.com/dogs/#{@dog.id}" }

    assert_response :redirect
    follow_redirect!
    assert_equal 'Attachment removed', flash[:notice]

    @dog.reload
    assert_equal @dog.images_attachments.length, 1
  end

  test "user that is not verified staff cannot delete an image attachment" do
    sign_in users(:user_two)

    patch "/dogs/#{@dog.id}",
      params: { dog:
        {
          organization_id: "#{organizations(:organization_one).id}",
          name: 'TestDog',
          age: '7',
          sex: 'Female',
          breed: 'mix',
          size: 'Medium (22-57 lb)',
          description: 'A lovely little pooch this one.',
          append_images:
          [
            fixture_file_upload("test.png", "image/png"),
            fixture_file_upload("test2.png", "image/png")
          ]
        }
      }

    assert_equal @dog.images_attachments.length, 2
    images = @dog.images_attachments
    logout

    sign_in users(:user_one)
    delete "/attachments/#{images[1].id}/purge",
      params: { id: "#{images[1].id}" },
      headers: { "HTTP_REFERER" => "http://www.example.com/dogs/#{@dog.id}" }

    follow_redirect!
    assert_equal '/', path
    assert_equal 'Unauthorized action.', flash[:alert]
  end

  test "verified staff can delete dog post" do
    sign_in users(:user_two)

    delete "/dogs/#{@dog.id}"

    assert_response :redirect
    follow_redirect!
    assert_select "h1", "Our dogs"
  end

  # test org dogs index page filter for adoption status
  test "verified staff accessing org dogs index without selection param see all unadopted dogs" do
    sign_in users(:user_two)

    get "/dogs"
    assert_response :success
    assert_select 'div.col-lg-4', { count: Dog.unadopted_dogs(@org_id).count }
  end

  test "verified staff accessing org dogs index with selection param seeking adoption see all unadopted dogs" do
    sign_in users(:user_two)
    get "/dogs",
    params: { selection: 'Seeking Adoption' }
    assert_response :success
    assert_select 'div.col-lg-4', { count: Dog.unadopted_dogs(@org_id).count }
  end

  test "verified staff accessing org dogs index with selection param adopted see all adopted dogs" do
    sign_in users(:user_two)
    get "/dogs",
    params: { selection: 'Adopted' }
    assert_response :success
    assert_select 'div.col-lg-4', { count: Dog.adopted_dogs(@org_id).count }
  end

  # test org dogs index page filter for dog name
  test "verified staff accessing org dogs index with a dog id see that dog only" do
    sign_in users(:user_two)
    get "/dogs",
    params: { dog_id: @dog.id }
    assert_response :success
    assert_select 'div.col-lg-4', { count: 1 }
    assert_select 'h5', "Deleted"
  end
end
