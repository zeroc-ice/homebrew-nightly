class IceAT39 < Formula
    desc "Comprehensive RPC framework"
    homepage "https://zeroc.com"

    version "3.9.0-nightly.20260213.2"
    url "https://github.com/zeroc-ice/ice/archive/e4edf04dfc0f5191ae106e7c16e9eb5240c2d13d.tar.gz"
    sha256 "e5afc3f6b648718d4c60c84cbf905c35a45546756ae0b3263c6ff1e5f7740e8f"

  bottle do
    root_url "https://download.zeroc.com/ice/nightly/3.9"
    rebuild 1
    sha256 cellar: :any, arm64_tahoe: "63a37fc8d88bada9d070b604347086b1a3814acdeab65c2907cf41edacb87048"
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
