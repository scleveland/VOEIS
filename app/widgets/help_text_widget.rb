class HelpTextWidget < Apotomo::Widget

  def display(options = {})
    @text = options[:text]
    @id = UUIDTools::UUID.timestamp_create
    render
  end

end
