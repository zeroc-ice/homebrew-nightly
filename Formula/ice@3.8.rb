class IceAT38 < Formula
    desc "Comprehensive RPC framework"
    homepage "https://zeroc.com"

    version "3.8.3-nightly.20260821.1"
    url "https://github.com/zeroc-ice/ice/archive/d5b9d7b76d07001855dd8cdfa17bb8646b5dce3d.tar.gz"
    sha256 "5f690a69dff448c5cf0a79d6c180bb2cee24f4848a285336b296a6b5528f0979"

  bottle do
    root_url "https://download.zeroc.com/ice/nightly/3.8"
    sha256 cellar: :any, arm64_tahoe: "fbfd0fa9e9156cbb6401e68268d0d1aa5f1485986819898b6df6c11f5d1b095e"
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
