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
    allow(Cloudinary::Uploader).to receive(:upload).and_return(UPLOAD_RESPONSE.dup)
    allow(Cloudinary::Uploader).to receive(:destroy).and_return("result" => "ok")
  end
end

RSpec.configure do |config|
  config.include CloudinaryStub, type: :request
end
