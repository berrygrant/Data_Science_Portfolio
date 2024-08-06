#!/usr/condabin/conda

from transformers import AutoTokenizer, DataCollatorForSeq2Seq, AutoModelForSeq2SeqLM, Seq2SeqTrainingArguments, Seq2SeqTrainer
from transformers import pipeline, TranslationPipeline
from datasets import load_dataset
import random
import pandas as pd
import torch
import argparse
import getpass
import os

user=getpass.getuser()

parser = argparse.ArgumentParser()
parser.add_argument('-d', '--dataset', help="This is the dataset for fine tuning. Choose one of 'bible','books', or 'science'. Selecting 'base' will test utterances on a base model without fine tuning.")
parser.add_argument('-t', '--test_set', default=os.getcwd()+"/test_set.txt")
parser.add_argument('-e','--epochs',help="Number of training iterations the model will go through. Default is 1",default=1)
args = parser.parse_args()

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(device)

def load_and_split(dataset,langs,test_size):
    res=load_dataset(dataset,langs)
    res=res["train"].train_test_split(test_size=test_size)
    return(res)

def preprocess_function(examples,tokenizer):
    inputs = [prefix + example[source_lang] for example in examples["translation"]]
    targets = [example[target_lang] for example in examples["translation"]]
    model_inputs = tokenizer(inputs, max_length=128, truncation=True)

    with tokenizer.as_target_tokenizer():
        labels = tokenizer(targets, max_length=128, truncation=True)

    model_inputs["labels"] = labels["input_ids"]
    return model_inputs

#Create function that loops through test set
def test_new_utts(translator,test_set):
    test_set=pd.read_csv(test_set,sep='\t',header=None)
    results=[translator(test_set.loc[line,0]) for line in range(0,test_set.shape[0])]
    return(results)

def training_args(epochs):
    training_args = Seq2SeqTrainingArguments(
    output_dir="./model",
    evaluation_strategy="epoch",
    learning_rate=2e-5,
    per_device_train_batch_size=16,
    per_device_eval_batch_size=16,
    weight_decay=0.01,
    save_total_limit=3,
    num_train_epochs=int(epochs),
    fp16=True,
)
    return(training_args)

def train_and_test(dataset,test_set,test_size):
    base_tokenizer = AutoTokenizer.from_pretrained("Helsinki-NLP/opus-mt-en-es")
    base_model = AutoModelForSeq2SeqLM.from_pretrained("Helsinki-NLP/opus-mt-en-es")
    base_collator = DataCollatorForSeq2Seq(tokenizer=base_tokenizer, model=base_model)
    print("Generating model for {}...".format(dataset))
    tokenizer = AutoTokenizer.from_pretrained("Helsinki-NLP/opus-mt-en-es")
    model=AutoModelForSeq2SeqLM.from_pretrained("Helsinki-NLP/opus-mt-en-es")
    collator = DataCollatorForSeq2Seq(tokenizer=tokenizer, model=model)   
    
    #Specify corpora based on fine tuning
    corp_dict={"bible":"bible_para","books":"opus_books","science":"scielo"}
    
    corpus=corp_dict[str(dataset)]
    print("Loading data from {} data...".format(dataset))
    data=load_and_split(corpus,"en-es",test_size)
    random_number=random.randint(0,99)
    print("Sample {} from {} corpus".format(random_number,dataset))
    data['train'][random_number]
    tokenized_data=data.map(lambda x: preprocess_function(x,tokenizer), batched=True)


    trainer=Seq2SeqTrainer(
    model = model,
    tokenizer=tokenizer,
    args = training_args(epochs),
    data_collator = collator,
    train_dataset = tokenized_data["train"],
    eval_dataset = tokenized_data["test"]
    )

    # Initialize training
    print("Beginning training sequence...")
    trainer.train()
    trainer.save_model(os.getcwd()+'/{}/models/{}_model'.format(user,dataset))
    model_local=model.to('cpu')

    print("Training complete. Now testing on test set...")

    #Initialize translator and test new utts
    translator=pipeline("translation_en_to_es",model=model,tokenizer=tokenizer)
    results=test_new_utts(translator, test_set)
    results=pd.DataFrame(results)
    results.to_csv(os.getcwd()+"/{}/{}_finetuning_results.txt".format(user,dataset),sep='\t')
    #results.to_csv("~/data/FineTuning_Lab/{}/{}_finetuning_results.txt".format(user,dataset),sep='\t')
    #print("Model has finished running. Please look in ~/data/FineTuning_Lab/{}/{}_finetuning_results/ for results.".format(user,user))
    return(results)

def test_base(test_set):
    print("Testing base model on {}".format(test_set))
    base_tokenizer = AutoTokenizer.from_pretrained("Helsinki-NLP/opus-mt-en-es")
    base_model = AutoModelForSeq2SeqLM.from_pretrained("Helsinki-NLP/opus-mt-en-es")
    base_collator = DataCollatorForSeq2Seq(tokenizer=base_tokenizer, model=base_model)
    translator=pipeline("translation_en_to_es",model=base_model,tokenizer=base_tokenizer)
    results=test_new_utts(translator, test_set)
    results=pd.DataFrame(results)
    results.to_csv(os.getcwd()+"/{}/base_results.txt".format(user),sep='\t')
    return(results)
    print("Completed.")

if __name__ == '__main__':
    if not os.path.isdir(os.getcwd()+"/"+user):
        os.mkdir(os.getcwd()+"/"+user)
    dataset=args.dataset
    test_set=args.test_set
    if dataset=='base':
        test_base(test_set)
    else:
        epochs=args.epochs
        source_lang = "en"
        target_lang = "es"
        test_size=0.2
        prefix = "Translate English to Spanish: "
        print("Training on {} dataset for {} epoch(s)".format(dataset,epochs))
        train_and_test(dataset,test_set,test_size)
    print("Script has finished.")