class IceAT39 < Formula
    desc "Comprehensive RPC framework"
    homepage "https://zeroc.com"

    version "3.9.0-nightly.20260724.1"
    url "https://github.com/zeroc-ice/ice/archive/6579fd3a3b801e4a2d19858d395e3c75c709a9f2.tar.gz"
    sha256 "211e751172e40313b49ab0f6b33b9a6cf644c8b9c62a5548fde104d558ac1eb6"

  bottle do
    root_url "https://download.zeroc.com/ice/nightly/3.9"
    sha256 cellar: :any, arm64_tahoe: "2c9c649d896cc12a7e05b0551036b49223bfe8caac34c5d89b8a9c3818f063c9"
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
      mv bin/"slice2py", libexec/"bin"
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
