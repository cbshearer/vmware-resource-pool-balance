# vmware-resource-pool-balance

1. Update the code to include your vCenter
1. You get a menu that gives you the option to:
    1. Loop through all vApps & Resource Pools to update settings
    2. Update just one vApp or Resource Pool
    3. List all vApps & Resource pools
2. If you select to update all, then
    1. Loop through each closter, in each cluster loop through all resource pools / vApps
    2. Display the current Cluster and Resource Pool / vApp
    3. Ask you to classify the system as (H)igh, (M)edium or (L)ow
    4. After you make a selection
        1. The current CPU and RAM shares are displayed in Green
        2. The RAM / CPU shares based on your input are displayed in Cyan
        3. If the values are different you can enter U to update them or N to not update the CPU shares
        4. If the values are different you can enter U to update them or N to not update the RAM shares
3. If you select to update just 1 resource pool, you are prompted to enter the name of the pool you want to update
    1. You enter the name and are asked to classify the system as (H)igh, (M)edium or (L)ow
    2. After you make a selection
        1. The current CPU and RAM shares are displayed in Green
        2. The RAM / CPU shares based on your input are displayed in Cyan
        3. If the values are different you can enter U to update them or N to not update the CPU shares
        4. If the values are different you can enter U to update them or N to not update the RAM shares
4. If you select to list all vApps and Resource Pools, all of the vApps / Resource pools are listed in green, with their associated cluster in parenthesis to the right in cyan.
