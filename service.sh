sleep 40

#Nice
renice -n -10 -p $(pidof msm_irqbalance)
renice -n -10 -p $(pgrep msm_irqbalance)

exit 0
