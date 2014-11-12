# encoding: UTF-8
module Paperclip
  class Fit < Processor
    attr_accessor :current_geometry, :target_geometry, :format

    def initialize(file, options = {}, attachment = nil)
      super
      geometry         = options[:geometry] # this is not an option
      @file            = file
      @target_geometry = (options[:string_geometry_parser] || Geometry).parse(geometry)
      @format          = options[:format]
      @current_format  = File.extname(@file.path)
      @basename        = File.basename(@file.path, @current_format)
    end

    def make
      src = @file
      dst = Tempfile.new([@basename, @format ? ".#{@format}" : ''])
      dst.binmode

      begin
        parameters = []
        parameters << ":source"
        parameters << transformation_command
        parameters << ":dest"

        parameters = parameters.flatten.compact.join(" ").strip.squeeze(" ")

        convert(parameters, :source => "#{File.expand_path(src.path)}#{'[0]'}", :dest => File.expand_path(dst.path))
      rescue Cocaine::ExitStatusError => e
        raise Paperclip::Error, "There was an error fitting for #{@basename}"
      rescue Cocaine::CommandNotFoundError => e
        raise Paperclip::Errors::CommandNotFoundError.new("Could not run the `convert` command. Please install ImageMagick.")
      end

      dst
    end

    def transformation_command
      trans = []
      trans << "-auto-orient"
      trans << "-strip"
      trans << "-resize" << %["#{target_geometry.width}x#{target_geometry.height}>"]
      trans
    end
  end
end
