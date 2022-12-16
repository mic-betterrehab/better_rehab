global class SDEPackageWrapper implements Comparable {

    public SDEPackage pack;

    // Constructor
    public SDEPackageWrapper(SDEPackage pack) {
        this.pack = pack;
    }

    // Compare opportunities based on the opportunity amount.
    global Integer compareTo(Object compareTo) {
        // Cast argument to OpportunityWrapper
        SDEPackageWrapper comparetoPack = (SDEPackageWrapper)compareTo;

        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (pack.totalDollar > comparetoPack.pack.totalDollar) {
            // Set return value to a positive value.
            returnValue = -1;
        } else if (pack.totalDollar < comparetoPack.pack.totalDollar) {
            // Set return value to a negative value.
            returnValue = 1;
        }

        return returnValue;       
    }
    
}