library(keras)
library(dplyr)
library(jsonlite)
library(readr)
library(magrittr)
library(caTools)
# samples <- c("The cat sat on the mat.", "The dog ate my homework.")

expert_data <- read_csv('Data/Train/Expert/data.csv')

set.seed(1993)




expert_train_ind <- sample.split(expert_data$sentiment, SplitRatio = 0.9)

expert_train <- expert_data[expert_train_ind,]
expert_test <- expert_data[!expert_train_ind, ]

max_features <- 500
maxlen <- 200

expert_train_tokenizer <- text_tokenizer(num_words = max_features) %>%
  fit_text_tokenizer(expert_train$text)

expert_train_sequences <- texts_to_sequences(expert_train_tokenizer, expert_train$text)

expert_train_x <- pad_sequences(expert_train_sequences, maxlen)


expert_model <- keras_model_sequential()%>%
  # Creates dense embedding layer; outputs 3D tensor
  # with shape (batch_size, sequence_length, output_dim)
  layer_embedding(input_dim = max_features, 
                  output_dim = 128,
                  input_length = maxlen
  ) %>%
  layer_flatten() %>% 
  layer_dense(units = 64, activation = 'tanh') %>%
  layer_dropout(rate = 0.7) %>% 
  layer_dense(units = 16, activation = 'tanh') %>% 
  layer_dropout(rate = 0.7) %>% 
  layer_dense(units = 4, activation = 'tanh') %>% 
  layer_dropout(rate = 0.7) %>% 
  layer_dense(units = 1, activation = 'sigmoid')


expert_model %>% compile(
  optimizer = "adam",
  loss = "binary_crossentropy",
  metrics = c("accuracy")
)

expert_history <- expert_model %>% fit(
  expert_train_x, 
  (as.numeric(as.factor(expert_train$sentiment)) - 1),
  epochs = 10,
  batch_size = 128,
  validation_split = 0.1
)


expert_test_tokenizer <- text_tokenizer(num_words = max_features) %>%
  fit_text_tokenizer(expert_test$text)

expert_test_sequences <- texts_to_sequences(expert_test_tokenizer, expert_test$text)

expert_test_x <- pad_sequences(expert_test_sequences, max_len)

mean(ifelse(predict(expert_model, expert_test_x) > 0.5, 1, 0) == expert_test$sentiment)