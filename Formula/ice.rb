class Ice < Formula
    desc "Comprehensive RPC framework"
    homepage "https://zeroc.com"

    version "3.8.0-nightly.20250624.1"
    url "https://github.com/zeroc-ice/ice/archive/361d3f226a4bb4c4cd6b98a04af8c1d54ba352d8.tar.gz"
    sha256 "114d3648ffe9ed4697dfac3e3418169af7b343d2b48463817006fddc0b465b80"

  bottle do
    root_url "https://download.zeroc.com/ice/nightly"
    sha256 cellar: :any, arm64_sequoia: "185cfc7695bf55453ccfe4a59eaa1f50adc2f11f7e6e53ac1a4739aa8af9f6f6"
  end

    depends_on "lmdb"
    depends_on "mcpp"

    def install
      args = [
        "prefix=#{prefix}",
        "V=1",
        "USR_DIR_INSTALL=yes", # ensure slice and man files are installed to share
        "MCPP_HOME=#{Formula["mcpp"].opt_prefix}",
        "LMDB_HOME=#{Formula["lmdb"].opt_prefix}",
        "CONFIGS=all",
        "PLATFORMS=all",
        "LANGUAGES=cpp",
      ]
      system "make", "install", *args

      (libexec/"bin").mkpath
      %w[slice2py slice2rb slice2js].each do |r|
        mv bin/r, libexec/"bin"
      end
    end

    test do
      (testpath / "Hello.ice").write <<~EOS
        module Test
        {
            interface Hello
            {
                void sayHello();
            }
        }
      EOS
      (testpath / "Test.cpp").write <<~EOS
        #include "Hello.h"
        #include <Ice/Ice.h>

        class HelloI : public Test::Hello
        {
        public:
            void sayHello(const Ice::Current&) override {}
        };

        int main(int argc, char* argv[])
        {
          Ice::CommunicatorHolder ich(argc, argv);
          auto adapter = ich->createObjectAdapterWithEndpoints("Hello", "default -h localhost");
          adapter->add(std::make_shared<HelloI>(), Ice::stringToIdentity("hello"));
          adapter->activate();
          return 0;
        }
      EOS

      system "#{bin}/slice2cpp", "Hello.ice"
      system "xcrun", "clang++", "-std=c++20", "-c", "-I#{include}", "Hello.cpp"
      system "xcrun", "clang++", "-std=c++20", "-c", "-I#{include}", "Test.cpp"
      system "xcrun", "clang++", "-L#{lib}", "-o", "test", "Test.o", "Hello.o", "-lIce", "-lpthread"
      system "./test"
    end
  end
