-- Deprecated.
set mapred.output.compress true
set pig.splitCombination true
set pig.maxCombinedSplitSize 1073741824
set pig.minCombinedSplitSize 1073741824
set mapreduce.job.reduce.slowstart.completedmaps 1.0
set mapred.reduce.tasks.speculative.execution true
set mapred.map.tasks.speculative.execution true
set job.name 'clean_cat'

SET output.compression.enabled true;
SET output.compression.codec org.apache.hadoop.io.compress.GzipCodec;
REGISTER 'jyson-1.0.2/lib/jyson-1.0.2.jar';
REGISTER 'amazon_data_udf.py' using jython AS udf;


%DEFAULT input_file '/user/recsys/rank_dev/yunjiang.jiang/amazon_data_processed/user_aggregated.tsv'
%DEFAULT output_file '/user/recsys/rank_dev/yunjiang.jiang/amazon_data_processed/user_aggregated.cleaned.tsv'
%DEFAULT num_parallel 100

/*
%DEFAULT input_file 'z'
%DEFAULT output_file 'y'
%DEFAULT num_parallel 1
*/

loaded = load '$input_file' using PigStorage('\t', '-schema');
generated = foreach loaded generate asin_hist, price_hist, overall_hist, brand_hist,
        overall, reviewerID, asin, reviewText, summary,
        flatten(udf.ConcatCategories(category)) as categories,
        description, title, rank, price, brand;
partitioned = foreach ( group generated by reviewerID parallel $num_parallel ) {
        generate flatten(generated) as (asin_hist, price_hist, overall_hist, brand_hist,
        overall, reviewerID, asin, reviewText, summary, categories,
        description, title, rank, price, brand);
};

rmf $output_file
STORE partitioned into '$output_file' using PigStorage('\t', '-schema');