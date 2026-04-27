# Masters_Thesis
A Master's thesis using multinomial logistic regression to predict MLB pitch sequences. Built pitcher-specific models for 767 pitchers in the 2025 season, achieving 62.4% accuracy—nearly double the baseline. Includes five model specifications, statistical comparisons, and an interactive R Shiny app for real-time predictions.

# MLB Pitch Sequence Prediction Using Multinomial Logistic Regression

## Project Overview

This repository contains the complete code, analysis, and deliverables for my Master's thesis on predicting pitch sequences in Major League Baseball. The project uses multinomial logistic regression to model pitcher decision-making based on real-time observable game state, achieving prediction accuracy of 62.4% compared to a 31.7% random baseline.

**Key Research Question:** Can we predict what pitch a pitcher will throw next based on game context (count, previous pitches, batter handedness) using classical statistical methods?

## Key Findings

1. **Game state drives selection** — The count (balls and strikes) is the dominant predictor, contributing a 12.62 percentage point accuracy gain
2. **Relief pitchers are more predictable** — The most predictable pitchers are typically relievers with narrow repertoires; elite starters cultivate unpredictability as a skill
3. **Model complexity must match data availability** — The most complex model (joint pitch type × location prediction) failed due to data sparsity, demonstrating that more parameters don't always yield better results
4. **Classical methods remain competitive** — Multinomial logistic regression achieved 62.36% accuracy while maintaining interpretability, matching neural network benchmarks from prior research

## Repository Contents

- **`Thesis_Paper.pdf`** — Complete thesis document with methodology, results, and analysis
- **`Thesis_Defense_Presentation.pdf`** — Defense presentation slides (technical and non-technical sections)
- **Model Code** — R scripts for all five model specifications:
  - `Simple_Logistic_Pitch_Type_Prediction.qmd` — Model 1: Basic pitch sequence model
  - `Simple_Logistic_Pitch_Type_Prediction_with_Stand.qmd` — Model 2: Added batter handedness
  - `Pitch_Prediction_Model_Basic.qmd` — Model 3: Full model with count and location
  - `Logistic_Pitch_Type_and_Pitch_Location_Separate_Prediction_2_Previous.qmd` — Model 4: Separate type/location models
  - `Logistic_Pitch_Type_and_Pitch_Location_Together_Prediction_2_Previous.qmd` — Model 5: Joint prediction

## Interactive Application

**[Live Shiny App](https://b-bruxvoort.shinyapps.io/pitch_type_prediction_app/)**

The R Shiny application allows users to:
- Select any 2025 MLB pitcher
- Input current game situation (count, previous pitch, batter side)
- View predicted pitch type probabilities
- See pitcher-specific model accuracy

The app demonstrates real-time pitch prediction and can be used for pre-game scouting, hitter preparation, or pitcher self-assessment.

## Live Presentation Link:

https://youtu.be/sYJX5PzjxbQ

## Data

**Source:** MLB Statcast 2025 regular season data from BaseballSavant  
**Scale:** 712,528 pitch observations across 767 pitchers  
**Variables:** Pitch type, location (zone), count (balls/strikes), batter handedness, pitch sequencing

Only variables observable in real-time during live gameplay were used—no spin rate, release point, or trajectory features—ensuring the models are implementable in actual game contexts.

## Methodology

**Model Type:** Multinomial logistic regression with pitcher-specific fitting  
**Key Innovation:** Lagged categorical variables (previous 1-2 pitch types and locations) to capture sequential decision-making  
**Evaluation:** Five model specifications compared via ANOVA and Tukey HSD post-hoc tests with Cohen's d effect sizes

### Five Model Specifications

| Model | Predictors | Mean Accuracy |
|-------|-----------|---------------|
| Model 1: Simple | Previous pitch types, pitch number | 47.20% |
| Model 2: Simple + Stand | Model 1 + batter handedness | 49.75% |
| **Model 3: Basic (Full)** | **Model 2 + count + previous zones** | **62.36%** |
| Model 4: Separate | Type model & zone model (combined) | 34.32% |
| Model 5: Interaction | Joint pitch type × zone outcome | 23.10% |

## Technologies Used

- **R** — Statistical computing and modeling
- **Quarto** — Reproducible research and documentation
- **nnet** — Multinomial logistic regression (`multinom()`)
- **Shiny** — Interactive web application
- **BaseballSavant** — Statcast pitch tracking data
- **ggplot2** — Data visualization

## Key Results

- **Overall prediction accuracy:** 62.36% (Model 3)
- **Baseline (random guess):** 31.7%
- **Improvement over baseline:** ~2× accuracy
- **Most predictable pitcher:** Tommy Kahnle (70.3% accuracy, relief pitcher)
- **Least predictable pitcher:** Seth Lugo (22.6% accuracy, starting pitcher)

## Practical Applications

- **Pre-game scouting reports** — Identify pitcher tendencies by count and situation
- **Hitter preparation** — Train against predicted pitch sequences
- **Pitcher self-assessment** — Evaluate predictability and adjust sequencing strategies
- **Coaching tool** — Analyze decision-making patterns across different game states

## Limitations

- Single season (2025 only) — no cross-season validation
- Static models — don't capture within-season adjustments
- Missing context — score differential, base-out state, bullpen availability not included
- No field experiment — cannot establish causal impact on offensive performance

## Future Research Directions

- Multi-season analysis to assess temporal stability
- Hierarchical Bayesian models to pool information across similar pitchers
- Recurrent neural networks for longer sequence memory
- Investigate correlation between predictability and pitcher effectiveness (ERA, WAR)
- Controlled field experiment to measure offensive improvement from pitch prediction

## Academic Context

- **Program:** Master of Science in Data Science and Analytical Storytelling
- **Institution:** Truman State University
- **Completion Date:** May 2026
- **Thesis Advisor:** Dr. Scott Alberts, Department of Computer and Data Sciences
- **Author:** Brian Bruxvoort

## Citation

If you use this work in your research, please cite:
Bruxvoort, B. (2026). Predicting Pitch Sequences in Baseball Using Multinomial Logistic Regression.
Master's Thesis, Truman State University.

## License

This project is available for academic and educational use. Please contact for commercial applications.

## Contact

For questions, collaboration opportunities, or access to the complete dataset and trained models, please reach out via GitHub or LinkedIn.

---

*This research demonstrates that classical statistical methods can effectively model sequential pitch selection while remaining interpretable and implementable in real-world baseball contexts.*
