library(dplyr)
library(ggplot2)
library(car)
library(brms)
library(emmeans)

set.seed(1234)

crd <- read.csv("results/crd_results.csv")

crd$k <- factor(crd$k, levels = c(3, 5, 10))

print(head(crd))
print(str(crd))

mean_ci <- function(x, conf = 0.95) {
  n <- length(x)
  m <- mean(x)
  s <- sd(x)
  se <- s / sqrt(n)
  tcrit <- qt((1 + conf) / 2, df = n - 1)
  margin <- tcrit * se

  data.frame(
    n = n,
    mean_f1 = m,
    sd = s,
    se = se,
    ci_lower = m - margin,
    ci_upper = m + margin
  )
}

crd_summary <- crd %>%
  group_by(k) %>%
  summarise(mean_ci(f1), .groups = "drop")

print(crd_summary)

write.csv(
  crd_summary,
  "results/crd_summary_r.csv",
  row.names = FALSE
)

levene_crd <- leveneTest(f1 ~ k, data = crd)

print(levene_crd)

capture.output(
  levene_crd,
  file = "results/crd_levene.txt"
)

lm_crd <- lm(f1 ~ k, data = crd)

print(summary(lm_crd))
print(anova(lm_crd))
print(confint(lm_crd))

capture.output(
  summary(lm_crd),
  anova(lm_crd),
  confint(lm_crd),
  file = "results/crd_lm.txt"
)

aov_crd <- aov(f1 ~ k, data = crd)

tukey_crd <- TukeyHSD(aov_crd)

print(tukey_crd)

capture.output(
  tukey_crd,
  file = "results/crd_tukey.txt"
)

png("figures/crd_tukey.png", width = 900, height = 600)
plot(tukey_crd)
dev.off()

p_crd <- ggplot(crd_summary, aes(x = k, y = mean_f1, group = 1)) +
  geom_line() +
  geom_point(size = 3) +
  geom_errorbar(
    aes(ymin = ci_lower, ymax = ci_upper),
    width = 0.15
  ) +
  labs(
    title = "CRD: Mean F1-score with 95% CI",
    x = "Number of folds k",
    y = "Mean F1-score"
  ) +
  theme_minimal()

ggsave(
  "figures/crd_mean_ci_r.png",
  p_crd,
  width = 6,
  height = 4,
  dpi = 300
)

brm_crd <- brm(
  f1 ~ k,
  data = crd,
  family = gaussian(),
  seed = 1234,
  chains = 4,
  iter = 2000,
  warmup = 1000
)

print(summary(brm_crd))

capture.output(
  summary(brm_crd),
  file = "results/crd_brm.txt"
)

emm_crd_brm <- emmeans(brm_crd, ~ k)
print(emm_crd_brm)
print(pairs(emm_crd_brm))

capture.output(
  emm_crd_brm,
  pairs(emm_crd_brm),
  file = "results/crd_brm_emmeans.txt"
)

saveRDS(
  brm_crd,
  "results/crd_brm_model.rds"
)