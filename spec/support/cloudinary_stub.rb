# frozen_string_literal: true

module CloudinaryStub
  UPLOAD_RESPONSE = {
    "public_id" => "flipflapp/avatars/test_avatar",
    "version" => "1234567890",
    "width" => 100,
    "height" => 100,
    "format" => "jpg",
    "resource_type" => "image",
    "type" => "upload",
    "secure_url" => "https://res.cloudinary.com/demo/image/upload/v1234567890/flipflapp/avatars/test_avatar.jpg",
    "url" => "http://res.cloudinary.com/demo/image/upload/v1234567890/flipflapp/avatars/test_avatar.jpg"
  }.freeze

  def stub_cloudinary_upload!
    configure_cloudinary_for_test!
    allow(Cloudinary::Uploader).to receive(:upload).and_return(UPLOAD_RESPONSE.dup)
    allow(Cloudinary::Uploader).to receive(:destroy).and_return("result" => "ok")
  end

  def configure_cloudinary_for_test!
    # Upload is stubbed; URL helpers still require cloud_name (unset in CI test job).
    Cloudinary.config do |config|
      config.cloud_name = ENV["CLOUDINARY_CLOUD_NAME"].presence || "demo"
      config.api_key = ENV["CLOUDINARY_API_KEY"].presence || "test_key"
      config.api_secret = ENV["CLOUDINARY_API_SECRET"].presence || "test_secret"
    end
  end
end

RSpec.configure do |config|
  config.include CloudinaryStub, type: :request
end
