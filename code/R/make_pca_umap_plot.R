#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)

library(dplyr)
library(data.table)
library(ggplot2)
library(cowplot)
library(uwot)

pca_filename <- args[1]
figure_filename <- args[2]
csv_filename <- args[3]
a_2D <- as.numeric(args[4])
b_2D <- as.numeric(args[5])

## convert XYZ to RGB
XYZ_RGB <-
  function(xyz) {

    # normalize X,Y,Z to convert to RGB
    X <- (xyz[, 1] - min(xyz[, 1])) /
      (max(xyz[, 1]) - min(xyz[, 1]))
    Y <- (xyz[, 2] - min(xyz[, 2])) /
      (max(xyz[, 2]) - min(xyz[, 2]))
    Z <- (xyz[, 3] - min(xyz[, 3])) /
      (max(xyz[, 3]) - min(xyz[, 3]))

    # in case there are missing values
    X[is.na(X)] <- 0
    Y[is.na(Y)] <- 0
    Z[is.na(Z)] <- 0

    # convert to RGB
    out <- rgb(
      unlist(X),
      unlist(Y),
      unlist(Z)
    )

    return(out)
  }

project_umap <-
  function(iid_pca_filename, a = 0.6, b = 0.9, n_dim, rgb = FALSE, a_3D = 0.05, b_3D = 1) {
    # column names
    cnames <- c("FID", "IID", paste0("U", 1:n_dim))
    # load pca projections
    iid_pca <- fread(iid_pca_filename, col.names = cnames)
    # remove first two ID columns
    p <- iid_pca[, -c(1, 2)]
    # Run UMAP on PC's
    umap_2D <- umap(p, n_components = 2, a = a, b = b)
    # bind to PCA data
    iid_umap_pca <- cbind(iid_pca, umap_2D) %>%
      dplyr::rename(UMAP1_2D = V1, UMAP2_2D = V2)

    if (rgb) {
      # Run UMAP on 20 PC's
      umap_3D <- umap(p, n_components = 3, a = a_3D, b = b_3D)
      iid_umap_pca$rgb <- XYZ_RGB(umap_3D)
    }

    # return pca and umap projections
    return(iid_umap_pca)
  }

plot_projection <-
  function(x, y, rgb = "black", xlab = "x", ylab = "y") {
    df <- tibble(x = x, y = y, rgb = rgb)
    out <- ggplot(df, aes(x = x, y = y, color = rgb)) +
      geom_point(size = 1) +
      scale_colour_identity() +
      theme_classic() +
      labs(x = xlab, y = ylab) +
      theme(
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_text(size = 10)
      )
    return(out)
  }


p <- project_umap(pca_filename, n_dim = 20, rgb = TRUE, a = a_2D, b = b_2D)

pca1 <- plot_projection(x = p$U1, y = p$U2, rgb = p$rgb, xlab = "PC 1", ylab = "PC 2")

pca2 <- plot_projection(x = p$U2, y = p$U4, rgb = p$rgb, xlab = "PC 2", ylab = "PC 4")

pca2 <- plot_projection(x = p$U3, y = p$U4, rgb = p$rgb, xlab = "PC 3", ylab = "PC 4")

pca3 <- plot_projection(x = p$U5, y = p$U6, rgb = p$rgb, xlab = "PC 5", ylab = "PC 6")

pca4 <- plot_projection(x = p$U7, y = p$U8, rgb = p$rgb, xlab = "PC 7", ylab = "PC 8")

pca5 <- plot_projection(x = p$U9, y = p$U10, rgb = p$rgb, xlab = "PC 9", ylab = "PC 10")

pca6 <- plot_projection(x = p$U11, y = p$U12, rgb = p$rgb, xlab = "PC 11", ylab = "PC 12")

umap <- plot_projection(x = p$UMAP1_2D, y = p$UMAP2_2D, rgb = p$rgb, xlab = "UMAP 1", ylab = "UMAP 2")

pca <- plot_grid(pca1, pca2, pca3, pca4, pca5, pca6)

out <- plot_grid(umap, pca)

ggsave(out, filename = figure_filename, height = 7, width = 16)

fwrite(p, csv_filename)
