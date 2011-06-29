class VerticalDatumWidget < Apotomo::Widget
  responds_to_event :submit, :with => :process_submit
  
  def display
    @vertical_datum = Voeis::VerticalDatumCV.new()
    render
  end
  
  def process_submit(evt)
    @vertical_datum = Voeis::VerticalDatumCV.new(evt[:voeis_vertical_datum_cv])
    begin
      @vertical_datum.save
    rescue
      puts @vertical_datum.errors.inspect()
    end
    replace :state => :display
  end
  
end
