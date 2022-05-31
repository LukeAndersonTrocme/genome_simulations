#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)

library(dplyr)
library(data.table)
library(ggplot2)
library(cowplot)
library(uwot)

set.seed(789)

n_dim <- 50

pca_filename <- args[1]
figure_filename <- args[2]
csv_filename <- args[3]

a_2D <- as.numeric(args[4])
b_2D <- as.numeric(args[5])

a_3D <- as.numeric(args[6])
b_3D <- as.numeric(args[7])

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
      unlist(Z),
      unlist(Y)
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
      # bind to PCA data
      iid_umap_pca <- cbind(iid_umap_pca, umap_3D) %>%
        dplyr::rename(UMAP1_3D = V1, UMAP2_3D = V2, UMAP3_3D = V3)
      # add 3D color
      iid_umap_pca$rgb <- XYZ_RGB(umap_3D)
    }
    # return pca and umap projections
    return(iid_umap_pca)
  }

plot_projection <-
  function(x, y, rgb = "black", xlab = "x", ylab = "y") {
    df <- tibble(x = x, y = y, rgb = rgb)
    out <- ggplot(df, aes(x = x, y = y, color = rgb)) +
      geom_point(size = 0.075, alpha = 0.6) +
      scale_colour_identity() +
      theme_classic() +
      labs(x = xlab, y = ylab) +
      theme(
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_text(size = 15)
      )
    return(out)
  }


p <- project_umap(pca_filename, n_dim = n_dim, rgb = TRUE, a = a_2D, b = b_2D, a_3D = a_3D, b_3D = b_3D)

fwrite(p, csv_filename)

pca1 <- plot_projection(x = p$U1, y = p$U2, rgb = p$rgb, xlab = "PC 1", ylab = "PC 2")

pca2 <- plot_projection(x = p$U3, y = p$U4, rgb = p$rgb, xlab = "PC 3", ylab = "PC 4")

pca3 <- plot_projection(x = p$U5, y = p$U6, rgb = p$rgb, xlab = "PC 5", ylab = "PC 6")

pca4 <- plot_projection(x = p$U7, y = p$U8, rgb = p$rgb, xlab = "PC 7", ylab = "PC 8")

pca5 <- plot_projection(x = p$U9, y = p$U10, rgb = p$rgb, xlab = "PC 9", ylab = "PC 10")

pca6 <- plot_projection(x = p$U11, y = p$U12, rgb = p$rgb, xlab = "PC 11", ylab = "PC 12")

pca7 <- plot_projection(x = p$U13, y = p$U14, rgb = p$rgb, xlab = "PC 13", ylab = "PC 14")

pca8 <- plot_projection(x = p$U15, y = p$U16, rgb = p$rgb, xlab = "PC 15", ylab = "PC 16")

pca9 <- plot_projection(x = p$U17, y = p$U18, rgb = p$rgb, xlab = "PC 17", ylab = "PC 18")

pca10 <- plot_projection(x = p$U19, y = p$U20, rgb = p$rgb, xlab = "PC 19", ylab = "PC 20")

pca11 <- plot_projection(x = p$U21, y = p$U22, rgb = p$rgb, xlab = "PC 21", ylab = "PC 22")

pca12 <- plot_projection(x = p$U23, y = p$U24, rgb = p$rgb, xlab = "PC 23", ylab = "PC 24")

pca13 <- plot_projection(x = p$U25, y = p$U26, rgb = p$rgb, xlab = "PC 25", ylab = "PC 26")

pca14 <- plot_projection(x = p$U27, y = p$U28, rgb = p$rgb, xlab = "PC 27", ylab = "PC 28")

pca15 <- plot_projection(x = p$U29, y = p$U30, rgb = p$rgb, xlab = "PC 29", ylab = "PC 30")

#umapA <- plot_projection(x = p$UMAP1_3D, y = p$UMAP2_3D, rgb = p$rgb, xlab = "UMAP 1", ylab = "UMAP 2")

#umapB <- plot_projection(x = p$UMAP1_3D, y = p$UMAP3_3D, rgb = p$rgb, xlab = "UMAP 1", ylab = "UMAP 3")

#umapC <- plot_projection(x = p$UMAP2_3D, y = p$UMAP3_3D, rgb = p$rgb, xlab = "UMAP 2", ylab = "UMAP 3")

umap2D <- plot_projection(x = p$UMAP1_2D, y = p$UMAP2_2D, rgb = p$rgb, xlab = "UMAP 1", ylab = "UMAP 2")

#umap3D <- plot_grid(umapA, umapB, umapC, nrow = 1)

#umap <- plot_grid(umap2D, umap3D, ncol = 1, rel_height = c(1.4, 1))

pca <- plot_grid(pca1, pca2, pca3, pca4, pca5,
                 pca6, pca7, pca8, pca9, pca10,
                 pca11, pca12, pca13, pca14, pca15,
                 nrow=3)

out <- plot_grid(umap2D, pca, nrow = 1)

ggsave(out, filename = figure_filename, height = 8, width = 16)
