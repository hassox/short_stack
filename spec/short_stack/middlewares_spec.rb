require 'spec_helper'

describe "short stack middleware" do
  before do
    class ::FooBar < ShortStack
      add_root(__FILE__)
    end
  end

  after do
    clear_constants :FooBar
  end

end
