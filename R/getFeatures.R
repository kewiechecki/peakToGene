#' Parses a genome file in GFF format into a list of \code{GRangesList}s organized by gene and genomic feature.
#'
#' @param gff Path to a genome file in GFF format.
#' @param prefix Prefix to append to gene IDs.
#' @param tssflank Numeric vector of length 2 giving the window in bp upstream and downstream of the TSS to use as the promoter.
#' @param tsswindow How many bp upstream of the promoter to consider as upstream of a gene.
#' @param ttswindow How many bp downstream of the TTS to consider as downstream of a gene.
#' @return 
#' @seealso \code{\link{mergeMotifs}}, \code{\link{motifmatchr::matchMotifs}}
#' @export
getFeatures <- function(
# accepts a GFF file name
# returns a list of GRangesLists corresponding to genomic features
  gff, # path to GFF
  prefix="KY2019:",
  tssflank=c(1107,107), # bp width around TSS to use as promoter
  tsswindow=10000, # bp width upstream of TSS
  ttswindow=10000, # bp width downstream of TTS
  ...
){
  # read data
  gff <- import(gff)
  # add fields for output as bed files
  gff$score <- 0
  gff$name <- gff$Parent

  # extract features by type
  res <- lapply(
	c('five_prime_UTR','CDS','three_prime_UTR'),
	function(x) {
		y <- gff[mcols(gff)$type==x]
		return(setNames(y,mcols(y)$Parent))
	}
  )
  names(res) <- c('five_prime_UTR','CDS','three_prime_UTR')

  # extract all features for each transcript
  gene <- gff[mcols(gff)$type%in%c("CDS",'five_prime_UTR','three_prime_UTR')]
  gene <- S4Vectors::split(gene,unlist(mcols(gene)$Parent))
  genebody <- unlist(range(gene))

  downstream <- flank(genebody,ttswindow,start=F)

  txdb <- makeTxDbFromGRanges(gff)
  
  introns <- unlist(intronsByTranscript(txdb,T))
  names(introns) <- paste0(prefix,names(introns))
  
  tss <- promoters(genebody,tssflank[1],tssflank[2])

  upstream <- flank(tss,tsswindow-tssflank[1])

  res2 <- list(upstream=upstream,promoter=tss,intron=introns,downstream=downstream)
  res2 <- append(res2,res)

  res2 <- lapply(res2, function(x) S4Vectors::split(x,sub('\\.v.*','',names(x))))

  return(res2)
}

#' Finds all overlaps between one of the genomic features returned by\code{getFeatures()} and a set of peaks, then returns a table of gene-to-peak associations.
#'
#' @param feat One of the \code{GRangesList}s returned by \code{getFeatures()}
#' @param peaks A \code{GRanges} object from the same genome as \code{feat}. It should have a \code{names()} attribute from \code{\link{namePeaks}}.
#' @return A \code{data.frame} of gene-to-peak mappings.
#' @export
getOverlaps <- function(feat,peaks){
	#peaks <- namePeaks(peaks)
	tmp <- findOverlaps(peaks,feat)
	res <- data.frame(
#                PeakID=peaks$name[from(tmp)],
                PeakID=names(peaks)[from(tmp)],
		GeneID=names(feat)[to(tmp)],
		stringsAsFactors=F
	)
	res <- res[!duplicated(res),]
	return(res)
}

#' Converts gene-peak table to a logical matrix of associations
#' 
#' @param overlaps A two-column matrix with peak IDs in the first column and gene IDs in the second column. It is intended to be used with the output of \code{getOverlaps}.
#' @return A logical matrix of gene-peak associations with genes as columns and peaks as rows.
#' @seealso \code{\link{getOverlaps}}
#' @export
getOverlapMat <- function(overlaps){
	peakid <- as.factor(overlaps[,1])
	geneid <- as.factor(overlaps[,2])
	peaks <- split(peakid,geneid)
	res <- sapply(peakid,function(x) sapply(peaks,function(y) x%in%y))
	colnames(res) <- names(peaks)
	return(res)
}

#' Assigns names to peaks.
#' 
#' @param peaks A GRanges object
#' @param prefix A string appended to the start of each name.
#' @export
namePeaks <- function(peaks,prefix=''){
  names(peaks) <- paste0(prefix,tolower(unlist(mapply(
    paste0,
    as.character(levels(droplevels(seqnames(peaks)))),'.',
    mapply(seq,1,table(droplevels(seqnames(peaks))))
  ))))
  return(peaks)
}
