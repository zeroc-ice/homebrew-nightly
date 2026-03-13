class IceAT39 < Formula
    desc "Comprehensive RPC framework"
    homepage "https://zeroc.com"

    version "3.9.0-nightly.20260313.2"
    url "https://github.com/zeroc-ice/ice/archive/169a8302c654bbd562334e7bb03ce5bf097b91e7.tar.gz"
    sha256 "1c4ae5c486f2037123c23ac0096cbf57cffe77f5cf3e4c119e4308f628aea737"

  bottle do
    root_url "https://download.zeroc.com/ice/nightly/3.9"
    sha256 cellar: :any, arm64_tahoe: "9c2aad39301c4bb1f4d9cee6cc9c6f0aafb9226898d0cd021a9d2c7e4c4abc02"
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
