FROM ruby:2.3 as builder

# Basic spec build and check packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y -qq \
    bison \
    build-essential \
    cmake \
    flex \
    fonts-lyx \
    ghostscript \
    git \
    imagemagick \
    libpango1.0-dev \
    libreadline-dev \
    pdftk \
    poppler-utils \
    python3 \
    python3-dev\
    python3-lxml \
    python3-networkx \
    python3-pillow \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    wget

RUN apt-get clean

# Basic gems
RUN gem install rake asciidoctor coderay json-schema 
RUN MATHEMATICAL_SKIP_STRDUP=1 gem install asciidoctor-mathematical
RUN gem install --pre asciidoctor-pdf

# Basic pip package
RUN pip3 install codespell
# pdf-diff pip package
RUN pip3 install git+https://github.com/JoshData/pdf-diff

# ImageMagick font config file - assuming the minimal install is why this didn't happen automatically
RUN wget http://www.imagemagick.org/Usage/scripts/imagick_type_gen && \
    mkdir -p ~/.magick && \
    find /usr/share/fonts/ -name '*.ttf' | perl imagick_type_gen -f - > ~/.magick/type.xml

# Second stage: start a simpler image that doesn't have the dev packages
FROM ruby:2.3 as ci

# Copy the generated font list
COPY --from=builder /root/.magick/type.xml /root/.magick/type.xml
# Copy locally-installed gems and python packages
COPY --from=builder /usr/local/ /usr/local/

# Runtime-required packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y -qq \
    fonts-lyx \
    ghostscript \
    git \
    imagemagick \
    libpango1.0-0 \
    libreadline7 \
    pdftk \
    poppler-utils \
    python-utidylib \
    python3 \
    python3-lxml \
    python3-networkx \
    python3-pillow \
    python3-pytest \
    python3-tabulate \
    wget

# Get clang-format-5.0
RUN echo "deb http://apt.llvm.org/stretch/ llvm-toolchain-stretch-5.0 main" >> /etc/apt/sources.list.d/llvm.list
RUN wget -O - http://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
RUN apt-get update -qq && apt-get install --no-install-recommends -y -qq clang-format-5.0

# Clean up after
RUN apt-get clean