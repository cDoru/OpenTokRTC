class Client < ActiveRecord::Base
  attr_accessible :flag, :imgdata, :point, :room_id, :name
  belongs_to :room
  before_save :uploadImage
	before_create :notify_creation
	before_destroy :notify_destruction

  def uploadImage
    ap self.imgdata
    ap "printed imgdata!"
    File.open("test.texts","wb") do |file|
      file.write((self.imgdata))
    end
    File.open("filename.png","wb") do |file|
      file.write(Base64.decode64(self.imgdata))
    end
    img = MiniMagick::Image.read(Base64.decode64(self.imgdata))
    #img = MiniMagick::Image.read(File.open("filename.png"))
    img.resize "100x100"
    img.format "png"

    filePath = "/clientImages/#{Time.now.to_f.to_s}.png"
    AWS::S3::S3Object.store( filePath, img.to_blob , S3Bucket, :access => :public_read )
    self.imgdata = S3URL+filePath
  end

	protected

	def notify_creation
    # When a client is created, the public channel for the whole app will be
		# notified
    Pusher[Webrtc::Application.config.application_channel].trigger('client-created', self.attributes)
	end

	def notify_destruction
    # When a client is destroyed, the public channel for the whole app will be
		# notified
    Pusher[Webrtc::Application.config.application_channel].trigger('client-destroyed', self.attributes)
	end
end
