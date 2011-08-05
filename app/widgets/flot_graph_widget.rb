class FlotGraphWidget < Apotomo::Widget

  def display(options={})
    @variable= options[:variable]
    @data = options[:data]
    render
  end

end
