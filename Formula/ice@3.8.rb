class IceAT38 < Formula
    desc "Comprehensive RPC framework"
    homepage "https://zeroc.com"

    version "3.8.2-nightly.20260421.1"
    url "https://github.com/zeroc-ice/ice/archive/18e5f89c156c17df678d5bdfc73a72854eb97f2f.tar.gz"
    sha256 "f01abfc1dd3a7135a4d1a6cb38953ea601a0d33bac4c6b2a69d5435c63cad20c"

  bottle do
    root_url "https://download.zeroc.com/ice/nightly/3.8"
    sha256 cellar: :any, arm64_tahoe: "f3da9f9be4274e8e6a47fd7d248d3e9a5512e00bec3ce7ccf5c6de418e416c8b"
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
