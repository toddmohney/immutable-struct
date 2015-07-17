require 'spec_helper.rb'

module TestModule
  def hello; "hello"; end
end

describe ImmutableStruct do
  describe "construction" do
    context "with non-boolean attributes and no body" do
      before do
        @klass = ImmutableStruct.new(:foo, :bar, :baz)
      end
      subject { @klass.new }

      it { should     respond_to(:foo) }
      it { should     respond_to(:bar) }
      it { should     respond_to(:baz) }
      it { should_not respond_to(:foo=) }
      it { should_not respond_to(:bar=) }
      it { should_not respond_to(:baz=) }
      it { should_not respond_to(:foo?) }
      it { should_not respond_to(:bar?) }
      it { should_not respond_to(:baz?) }

      context "instances can be created with a hash" do
        subject { @klass.new(foo: "FOO", bar: 42, baz: [:a,:b,:c]) }

        it { subject.foo.should == "FOO" }
        it { subject.bar.should == 42 }
        it { subject.baz.should == [:a,:b,:c] }
      end
    end

    context "intelligently handles boolean attributes" do
      subject { ImmutableStruct.new(:foo?) }

      context "with boolean values" do
        it { subject.new(foo: false).foo?.should == false }
        it { subject.new(foo: false).foo.should == false }
        it { subject.new(foo: true).foo?.should == true }
        it { subject.new(foo: true).foo.should == true }
      end

      context "with falsey, non-boolean values" do
        it { subject.new.foo?.should == false }
        it { subject.new.foo.should == nil }
      end

      context "with truthy, non-boolean values" do
        it { subject.new(foo: "true").foo?.should == true }
        it { subject.new(foo: "true").foo.should == "true" }
      end

    end

    context "allows for values that should be coerced to collections" do
      it "can define an array value that should never be nil" do
        klass = ImmutableStruct.new([:foo], :bar)
        instance = klass.new
        instance.foo.should == []
        instance.bar.should == nil
      end
    end

    it "allows defining instance methods" do
      klass = ImmutableStruct.new(:foo, :bar) do
        def derived; self.foo + ":" + self.bar; end
      end
      instance = klass.new(foo: "hello", bar: "world")
      instance.derived.should == "hello:world"
    end

    it "allows defining class methods" do
      klass = ImmutableStruct.new(:foo, :bar) do
        def self.from_array(array)
          self.new(foo: array[0], bar: array[1])
        end
      end
      instance = klass.from_array(["hello","world"])
      instance.foo.should == "hello"
      instance.bar.should == "world"
    end

    it "allows module inclusion" do
      klass = ImmutableStruct.new(:foo) do
        include TestModule
      end
      instance = klass.new

      instance.should  respond_to(:hello)
      klass.should_not respond_to(:hello)
    end

    it "allows module extension" do
      klass = ImmutableStruct.new(:foo) do
        extend TestModule
      end
      instance = klass.new

      instance.should_not respond_to(:hello)
      klass.should        respond_to(:hello)
    end
  end

  describe "to_h" do
    it "should include the output of params and block methods in the hash" do
      klass = ImmutableStruct.new(:name, :minor?, :location, [:aliases]) do
        def nick_name
          'bob'
        end
      end
      instance = klass.new(name: "Rudy", minor: "ayup", aliases: [ "Rudyard", "Roozoola" ])
      instance.to_h.should == {
        name: "Rudy",
        minor: "ayup",
        minor?: true,
        location: nil,
        aliases: [ "Rudyard", "Roozoola"],
        nick_name: "bob",
      }
    end
  end
end
