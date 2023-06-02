FROM rocker/r2u:22.04

LABEL SOFTWARE_NAME R with custom packages
LABEL MAINTAINER "Tom Harrop"

# use the VERSION file to set the version label
COPY VERSION /app/VERSION
RUN export VERSION=$(cat /app/VERSION) && \
    echo "VERSION=$VERSION" >> /etc/environment
LABEL version=$VERSION

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C

RUN     apt-get clean && \
        rm -r /var/lib/apt/lists/*

# update
RUN     . /etc/os-release \
        echo "deb mirror://mirrors.ubuntu.com/mirrors.txt ${UBUNTU_CODENAME} main restricted universe multiverse" >> mirror.txt && \
        echo "deb mirror://mirrors.ubuntu.com/mirrors.txt ${UBUNTU_CODENAME}-updates main restricted universe multiverse" >> mirror.txt && \
        echo "deb mirror://mirrors.ubuntu.com/mirrors.txt ${UBUNTU_CODENAME}-backports main restricted universe multiverse" >> mirror.txt && \
        echo "deb mirror://mirrors.ubuntu.com/mirrors.txt ${UBUNTU_CODENAME}-security main restricted universe multiverse" >> mirror.txt && \
        mv /etc/apt/sources.list /etc/apt/sources.list.bak && \
        cat mirror.txt /etc/apt/sources.list.bak > /etc/apt/sources.list && \
        apt-get update && apt-get upgrade -y --fix-missing


# missing dependencies
# libgdal-dev is required for adegenet (dependencies sf/spdep), but it's
# missing in the bioconductor container. apt install libgdal-dev fails unless
# libmysqlclient-dev and default-libmysqlclient-dev are installed manually.
RUN     apt-get install -y \
            default-libmysqlclient-dev \
            libgdal-dev \
            libmysqlclient-dev

# tidy up
RUN     apt-get autoremove --purge -y && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

# r packages
RUN     Rscript -e "install.packages(c( \
                'adegenet', \
                'apeglm', \
                'ashr', \
                'Biostrings', \
                'Cairo', \
                'circlize', \
                'cowplot', \
                'dada2', \
                'data.table', \
                'DESeq2', \
                'DEXSeq', \
                'extrafont', \
                'future.apply', \
                'GenomicAlignments', \
                'GenomicFeatures', \
                'GenomicRanges', \
                'ggimage', \
                'ggtree', \
                'gtools', \
                'Gviz', \
                'hexbin', \
                'Mfuzz', \
                'pheatmap', \
                'phyloseq', \
                'rehh', \
                'rtracklayer', \
                'ShortRead', \
                'SNPRelate', \
                'sysfonts', \
                'systemPipeR', \
                'tidyverse', \
                'tximeta', \
                'tximport', \
                'UpSetR', \
                'valr', \
                'VariantAnnotation', \
                'vcfR', \
                'VennDiagram', \
                'viridis' \
                ), \
            ask=FALSE)"

# plotting extras
RUN     wget -O "lato.zip" \
            http://www.latofonts.com/download/Lato2OFL.zip && \
        unzip lato.zip && \
        mv Lato2OFL /usr/share/fonts/truetype/ && \
        rm lato.zip && \
        fc-cache -f -v

RUN     Rscript -e "library('extrafont') ; \
            font_import(prompt=FALSE) ; \
            loadfonts()"

ENTRYPOINT ["/usr/local/bin/R"]
