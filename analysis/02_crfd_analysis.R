library(dplyr)
library(ggplot2)
library(car)
library(brms)
library(emmeans)

set.seed(1234)

crfd <- read.csv("results/crfd_results.csv")

crfd$k <- factor(crfd$k, levels = c(3, 5, 10))
crfd$max_depth <- factor(
  crfd$max_depth,
  levels = c("3", "5", "None")
)

print(head(crfd))
print(str(crfd))

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

crfd_summary <- crfd %>%
  group_by(k, max_depth) %>%
  summarise(mean_ci(f1), .groups = "drop")

print(crfd_summary)

write.csv(
  crfd_summary,
  "results/crfd_summary_r.csv",
  row.names = FALSE
)

summary_k <- crfd %>%
  group_by(k) %>%
  summarise(mean_ci(f1), .groups = "drop")

summary_depth <- crfd %>%
  group_by(max_depth) %>%
  summarise(mean_ci(f1), .groups = "drop")

write.csv(summary_k, "results/crfd_summary_k_r.csv", row.names = FALSE)
write.csv(summary_depth, "results/crfd_summary_depth_r.csv", row.names = FALSE)

lm_crfd <- lm(f1 ~ k * max_depth, data = crfd)

print(summary(lm_crfd))
print(anova(lm_crfd))
print(confint(lm_crfd))

capture.output(
  summary(lm_crfd),
  anova(lm_crfd),
  confint(lm_crfd),
  file = "results/crfd_lm.txt"
)

crfd$treatment <- interaction(crfd$k, crfd$max_depth)

levene_crfd <- leveneTest(f1 ~ treatment, data = crfd)

print(levene_crfd)

capture.output(
  levene_crfd,
  file = "results/crfd_levene.txt"
)

p_interaction <- ggplot(
  crfd_summary,
  aes(
    x = max_depth,
    y = mean_f1,
    group = k,
    linetype = k,
    shape = k
  )
) +
  geom_line() +
  geom_point(size = 3) +
  geom_errorbar(
    aes(ymin = ci_lower, ymax = ci_upper),
    width = 0.15
  ) +
  labs(
    title = "CRFD: Interaction between k and max_depth",
    x = "max_depth",
    y = "Mean F1-score",
    linetype = "k",
    shape = "k"
  ) +
  theme_minimal()

ggsave(
  "figures/crfd_interaction_r.png",
  p_interaction,
  width = 7,
  height = 4.5,
  dpi = 300
)

brm_crfd <- brm(
  f1 ~ k * max_depth,
  data = crfd,
  family = gaussian(),
  seed = 1234,
  chains = 4,
  iter = 2000,
  warmup = 1000
)

print(summary(brm_crfd))

capture.output(
  summary(brm_crfd),
  file = "results/crfd_brm.txt"
)

emm_crfd_brm <- emmeans(brm_crfd, ~ k * max_depth)

print(emm_crfd_brm)

capture.output(
  emm_crfd_brm,
  file = "results/crfd_brm_emmeans.txt"
)

saveRDS(
  brm_crfd,
  "results/crfd_brm_model.rds"
)