# frozen_string_literal: true

module BlogsHelper
  def format_content(blog)
    sanitize(simple_format(blog.content))
  end
end
