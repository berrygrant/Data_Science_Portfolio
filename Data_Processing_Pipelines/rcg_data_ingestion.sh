 #! /bin/bash/

# This shell script automates data preprocessing of speech data for Berry & Toscano's Research Catalyst Grant (2022-2024)


# Delete file breadcrumbs from failed runs
echo "Deleting breadcrumbs..."
find "/mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/" -type f -size -50c -exec rm {} \;

echo "Starting data processing..."

# Concatenate files
echo Step 1: Concatenating Sound Files...
praat /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Adaptation_Prep_GPU.praat

#Copy audio files to aligned directories
echo Step 2: Copying wav files and TextGrids...
cp /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Concatenated_Data/*wav /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data_ARPA/
cp /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Concatenated_Data/*wav /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data/
cp /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Concatenated_Data/*TextGrid /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data_ARPA/
cp /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Concatenated_Data/*TextGrid /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data/
# Align files with MFA and ARPA
echo Step 3: Force-aligning Sound Files...
mfa align /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Concatenated_Data/ english_us_arpa english_us_arpa /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data_ARPA/ --overwrite  --textgrid_cleanup --clean

mfa align /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Concatenated_Data/ english_mfa english_mfa /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data/ --overwrite  --textgrid_cleanup --clean


# Group speakers by Sex. Hard-coding speakers is preferred to ensure that we have carefully reviewed demographic data prior to processing
echo Step 4: Extracting Formants...
males=("S202" "S203" "S204" "S205" "S207" "S209" "S210" "S212" "S217" "S218" "S228" "S229" "S234" "S235" "S240" "S242" "S243" "S244" "S245" "S246" "S251" "S253" "S254")

females=("S201" "S206" "S208" "S211" "S213" "S214" "S215" "S216" "S219" "S220" "S221" "S222" "S223" "S224" "S225" "S226" "S230" "S231" "S232" "S236" "S237" "S238" "S239" "S241" "S247" "S248" "S249" "S252")

for male in ${males[@]}; do 
	mkdir -p /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data_ARPA/Males/; 
	mv /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data_ARPA/${male}* /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data_ARPA/Males/;
	mkdir -p /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data/Males/;
	mv /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data/${male}* /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data/Males/; 
	done

for female in ${females[@]}; do 
	mkdir -p /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data_ARPA/Females/; 
	mv /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data_ARPA/${female}* /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data_ARPA/Females/;
	mkdir -p /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data/Females/;
	mv /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data/${female}* /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Tasks/3_ADAPTATION/Aligned_Data/Females/; 
	done

praat /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Adaptation_ExtractFormants_Male.praat
praat /mnt/LUV_LAB_NAS/Lab_Studies/RCG_2023/Adaptation_ExtractFormants_Female.praat

echo "Done."
