require 'spec_helper'

describe ShortStack do

  before do
    @master_before = [Pancake.master_stack, Pancake.master_templates]
    $captures = []
    class ::ShortMiddle
      attr_accessor :app
      def initialize(app)
        @app = app
      end

      def call(env)
        $captures << ShortMiddle
        @app.call(env)
      end
    end

    class ::ShortFoo < ShortStack
      roots << Pancake.get_root(__FILE__)
      add_root(__FILE__, "..", "fixtures", "foobar")
      add_root(__FILE__, "..", "fixtures", "foobar", "other_root")
      use ShortMiddle

      get "/foo" do
        "HERE"
      end

      get "/" do
        $captures << self.class
        render :inherited_from_base
      end
    end

    @app = ShortFoo
    Pancake.master_stack = ShortFoo
    Pancake.master_templates = ShortFoo
  end

  after do
    clear_constants :ShortFoo, :ShortMiddle, :OtherFoo, :AnotherFoo, "ShortFoo::Router"
    Pancake.master_stack, Pancake.master_templates = @master_before
  end

  def app
    @app.stackup
  end

  it "should provide access through the stack interface to the templates" do
    ShortFoo.template(:inherited_from_base).should be_an_instance_of(Pancake::Mixins::Render::Template)
  end

  it "should go through the middleware to get to the actions" do
    get "/foo"
    $captures.should == [ShortMiddle]
  end

  describe "inheritance" do
    before do
      class ::OtherFoo   < ShortFoo; end
      class ::AnotherFoo < ShortFoo; end
      AnotherFoo.router.mount(OtherFoo, "/other")
      AnotherFoo.include_pancake_stack!
    end

    def app
      AnotherFoo.stackup
    end

    it "should render the same template in the child as it does in the parent" do
      get "/"
      $captures.pop.should == AnotherFoo::Controller
      last_response.should match(/inherited from base/)
      result = get "/other/"
      $captures.pop.should == OtherFoo::Controller
      last_response.should match(/inherited from base/)
    end
  end

  describe "helpers" do
    before do
      $captures = []
      class ::ShortFoo
        helpers do
          def in_helper?
            $captures << :in_helper?
          end
        end
      end
    end

    it "should allow me to setup a helper method in the stack" do
      ShortFoo.get("/with_helper"){ in_helper?; "OK" }
      result = get "/with_helper"
      result.should be_successful
      $captures.should include(:in_helper?)
    end

    it "should provide the helpers in child stacks" do
      class ::OtherFoo < ShortFoo; end
      OtherFoo.get("/helper_action"){ in_helper?; "OK" }
      @app = OtherFoo
      result = get "/helper_action"
      result.should be_successful
      $captures.should include(:in_helper?)
    end

    it "should let me mixin modules to the helpers" do
      module ::OtherFoo
        def other_helper
          $captures << :other_helper
        end
      end
      ShortFoo.helpers{ include OtherFoo }
      ShortFoo.get("/foo"){ other_helper; "OK" }
      result = get "/foo"
      result.should be_successful
      $captures.should include(:other_helper)
    end
  end
end
