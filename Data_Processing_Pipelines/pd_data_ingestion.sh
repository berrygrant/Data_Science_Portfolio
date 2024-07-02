 #! /bin/bash/

# This script is designed to automated the data processing steps for data from a project on phonetic drift in Spanish language learners
# Please note that this script must be run from an environment where the Montreal Forced Aligner is installed
# Please note that PRAAT must be installed for command-line use
echo "Concatenating audio files and creating grids...\n----------"
cd /mnt/LUV_LAB_NAS/Lab_Studies/Drift_Spanish_Experiment/
praat /mnt/LUV_LAB_NAS/Lab_Studies/Drift_Spanish_Experiment/concatenate_driftdata.praat

echo "Files concatenated. Now aligning using MFA...\n----------"

#Note: Need spanish_mfa acoustic model, pronouncing dictionary, and language model installed. Uncommont lines below if you don't have them
#mfa model download acoustic spanish_mfa --ignore_cache
#mfa model download language_model spanish_mfa_lm --ignore_cache
#mfa model download dictionary spanish_mfa --ignore_cache
mfa align /mnt/LUV_LAB_NAS/Lab_Studies/Drift_Spanish_Experiment/Analysis/Concatenated_Data/ spanish_mfa spanish_mfa /mnt/LUV_LAB_NAS/Lab_Studies/Drift_Spanish_Experiment/Analysis/Aligned_Data/ --overwrite  --textgrid_cleanup --clean -s 4

echo "Files aligned. Now copying audio files... \n----------"
cp /mnt/LUV_LAB_NAS/Lab_Studies/Drift_Spanish_Experiment/Analysis/Concatenated_Data/*wav /mnt/LUV_LAB_NAS/Lab_Studies/Drift_Spanish_Experiment/Analysis/Aligned_Data/

echo "Files copied. Now extracting acoustic-based metrics... \n----------"
praat /mnt/LUV_LAB_NAS/Lab_Studies/Drift_Spanish_Experiment/extract_th_metrics.praat

echo "Process completed."