certstrap sign \
     --expires "3 year" \
     --csr csr/Test_Org_v1_ICA1_v1.csr \
     --cert out/Intermediate_CA1_v1.crt \
     --intermediate \
     --CA "Testing Root" \
     "Intermediate CA1 v1"
