class Ice < Formula
    desc "Comprehensive RPC framework"
    homepage "https://zeroc.com"

    version "3.8.0-nightly.20250627.2"
    url "https://github.com/zeroc-ice/ice/archive/9f631c00d4ddfdc440b255a5211c639983d3dccd.tar.gz"
    sha256 "e668d6d9919529ff8542f0ea5447c2cdb450fee0cfcf3cb913a873911a159d58"

  bottle do
    root_url "https://download.zeroc.com/ice/nightly"
    sha256 cellar: :any, arm64_sequoia: "9a6b2ef983ce24e562275be4f7cf8e6dc342cff65a650fb4692d4d92f6dfe321"
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
