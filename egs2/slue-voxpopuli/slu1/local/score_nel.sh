log_dir=$1 # directory to save results
token_fn=$2 # decoded frame-level outputs
split=$3
tune=$4 # 1: tune, 0: don't tune
# split="devel"

if ! test -f "data/nel_gt/${split}_all_word_alignments.json"; then
    python local/prepare_nel_data.py
fi

if [[ "$log_dir" == *"whisper"* ]]; then
    python local/reformat_ctc_outputs.py --token_fn $token_fn --log_dir $log_dir --split $split --frame_len 2e-2
elif [[ "$log_dir" == *"slurp"* ]]; then
    python local/reformat_ctc_outputs.py --token_fn $token_fn --log_dir $log_dir --split $split --frame_len 0.032
else
    python local/reformat_ctc_outputs.py --token_fn $token_fn --log_dir $log_dir --split $split --frame_len 4e-2
fi

if [ "$split" = "test" ]; then
    python local/score_nel.py eval_test --log_dir $log_dir
elif [ "$tune" -eq 1 ]; then
    for offset in $(seq -0.3 0.02 0.3); do
        python local/score_nel.py evaluate_submission --log_dir $log_dir --split $split --ms False --offset $offset
    done
    python local/score_nel.py choose_best --log_dir $log_dir
else
    offset=0.0
    python local/score_nel.py evaluate_submission --log_dir $log_dir --split $split --ms False --offset 0.0
fi