# frozen_string_literal: true

require "chunky_png"

module Helpers
  # Module for working with image files. Required for visual diff testing
  module ImageHelper
    # based on https://jeffkreeftmeijer.com/ruby-compare-images
    # @param first_image_path String abs path of first image for comparison
    # @param second_image_path String abs path of second image for comparison
    # @param diff_image_path String abs path for saving diff image if diff will found
    # @return Float pixels changed percentage
    def compare_images(first_image_path, second_image_path, diff_image_path)
      images = [ChunkyPNG::Image.from_file(first_image_path), ChunkyPNG::Image.from_file(second_image_path)]
      diff = create_diff(images)
      save_diff_image(images, diff, diff_image_path) if diff.any?
      calc_pixels_changed_percentage(images, diff)
    end

    private

    def create_diff(images)
      diff = []
      images.first.height.times do |y|
        images.first.row(y).each_with_index { |pixel, x| diff << [x, y] unless pixel == images.last[x, y] }
      end
      diff
    end

    def save_diff_image(images, diff, diff_image_path)
      x = diff.map { |xy| xy[0] }
      y = diff.map { |xy| xy[1] }

      images.last.rect(x.min, y.min, x.max, y.max, ChunkyPNG::Color.rgb(0, 255, 0))
      images.last.save(diff_image_path)
    end

    def calc_pixels_changed_percentage(images, diff)
      ((diff.length.to_f / images.first.pixels.length) * 100).round(4)
    end
  end
end
