#' Converter for Proteome discoverer PSM sheet to MSstats.
#'
#' Stupid question: Is proteome discoverer the thermo fisher software?  I have
#' only seen our MSMS person using it, but it looks eminently hate-able.
#'
#' @param input Proteome discoverer PSM sheet to convert
#' @param annotation  Dataframe of peptide/protein annotations.
#' @param useNumProteinsColumn  What it says on the tin?  Though I am curious
#'   why one would not want that information, is it not useful?
#' @param useUniquePeptide  Instead of Proteins, use the Unique Peptides?
#' @param summaryforMultipleRows  Presumably this is the function passed to
#'   aggregate, but I haven't read this code carefully yet.
#' @param fewMeasurements  What to do with the drunken sailor^H^H^H the peptides
#'   with few measurements.
#' @param removeOxidationMpeptides  This is another parameter which leaves me
#'   thinking that there is a reason one would want to remove oxidation
#'   products, but I do not know what it is.
#' @param removeProtein_with1Peptide  Does what it says on the poorly labeled
#'   tin.
#' @param which.quantification  Which column to use for quantification?
#' @param which.proteinid  Choose a column for gathering protein IDs.
#' @param which.sequence  Which column contains the peptide sequence?
#' @return A dataframe suitable for dataProcess()
#' @export
PDtoMSstatsFormat <- function(input, annotation, useNumProteinsColumn=FALSE, useUniquePeptide=TRUE,
                              summaryforMultipleRows=max, fewMeasurements="remove",
                              removeOxidationMpeptides=FALSE, removeProtein_with1Peptide=FALSE,
                              which.quantification="Precursor.Area",
                              which.proteinid="Protein.Group.Accessions",
                              which.sequence="Sequence") {

################################################
### 0.1. which intensity : Precursor.Area vs. Intensity vs Area
################################################
  ## 2017.01.11 : use 'Precursor.Area' instead of 'Intensity'
  ## default : Precursor.Area
  which.quant <- NULL

  if (which.quantification == "Intensity") {
    which.quant <- "Intensity"
  } else if (which.quantification == "Area") {
    which.quant <- "Area"
  } else if (which.quantification == "Precursor.Area") {
    which.quant <- "Precursor.Area"
  }

  if (is.null(which.quant)) {
    stop(strwrap(prefix=" ", initial="",
                 "** Please select which columns should be used for quantified intensities, among three
options (Intensity, Area, Precursor.Area)."))
  }

  if (which.quant == "Intensity" & !is.element("Intensity", colnames(input))) {
    ## then that is because, input came from different version
    which.quant <- "Precursor.Area"
    message("** Use Precursor.Area instead of Intensity.")
  }
  if (which.quant == "Area" & !is.element("Area", colnames(input))) {
    ## then that is because, input come from different version
    which.quant <- "Precursor.Area"
    message("** Use Precursor.Area instead of Intensity.")
  }
  if (which.quant == "Precursor.Area" & !is.element("Precursor.Area", colnames(input))) {
    ## then that is because, input come from different version
    stop(strwrap(prefix=" ", initial="",
                 "** Please select which columns should be used for quantified intensities,
 among two options (Intensity or Area)."))
  }

  if (!is.element(which.quant, colnames(input))) {
    stop(strwrap(prefix=" ", initial="",
                 "** Please select which columns should be used for quantified intensities,
among three options (Intensity, Area, Precursor.Area)."))
  }

################################################
### 0.2. which protein id : Protein Accessions vs Master Protein Accesisions
################################################
  ## default : Protein Accessions
  which.pro <- NULL

  if (which.proteinid == "Protein.Accessions") {
    which.pro <- "Protein.Accessions"
  } else if (which.proteinid == "Master.Protein.Accessions") {
    which.pro <- "Master.Protein.Accessions"
  } else if (which.proteinid == "Protein.Group.Accessions") {
    which.pro <- "Protein.Group.Accessions"
  }

  if (is.null(which.pro)) {
    stop(strwrap(prefix=" ", initial="",
                 "** Please select which columns should be used for protein ids, among three
 options (Protein.Accessions, Master.Protein.Accessions, Protein.Group.Accessions)."))
  }

  if (which.pro == "Protein.Accessions" & !is.element("Protein.Accessions", colnames(input))) {
    which.pro <- "Protein.Group.Accessions"
    message("** Use Protein.Group.Accessions instead of Protein.Accessions.")
  }
  if (which.pro == "Master.Protein.Accessions" &
      !is.element("Master.Protein.Accessions", colnames(input))) {
    which.pro <- "Protein.Group.Accessions"
    message("** Use Protein.Group.Accessions instead of Master.Protein.Accessions.")
  }
  if (which.pro == "Protein.Group.Accessions" &
      !is.element("Protein.Group.Accessions", colnames(input))) {
    ## then that is because, input come from different version
    stop(strwrap(prefix=" ", initial="",
                 "** Please select which columns should be used for protein ids, among two
 options (Protein.Accessions or Master.Protein.Accessions)."))
  }
  if (!is.element(which.pro, colnames(input))) {
    stop(strwrap(prefix=" ", initial="",
                 "** Please select which columns should be used for protein ids, among three
 options (Protein.Accessions, Master.Protein.Accessions, Protein.Group.Accessions)."))
  }

################################################
### 0.3. which sequence : Sequence vs Annotated.Sequence
################################################
  ## default : Sequence
  which.seq <- NULL

  if (which.sequence == "Annotated.Sequence") {
    which.seq <- "Annotated.Sequence"
  } else if (which.sequence == "Sequence") {
    which.seq <- "Sequence"
  }
  if (is.null(which.sequence)) {
    stop(strwrap(prefix=" ", initial="",
                 "** Please select which columns should be used for peptide sequence, between
 two options (Sequence or Annotated.Sequence)."))
  }
  if (which.seq == "Annotated.Sequence" & !is.element("Annotated.Sequence", colnames(input))) {
    which.seq <- "Sequence"
    message("** Use Sequence instead of Annotated.Sequence.")
  }
  if (!is.element(which.seq, colnames(input))) {
    stop(strwrap(prefix=" ", initial="",
                 "** Please select which columns should be used for peptide sequence, between
 two options (Sequence or Annotated.Sequence)."))
  }

################################################
### 1. get subset of columns
################################################
  input <- input[, which(colnames(input) %in% c(which.pro, "X..Proteins",
                                                "Sequence", "Modifications", "Charge",
                                                "Spectrum.File", which.quant))]

  colnames(input)[colnames(input) == "Protein.Group.Accessions"] <- "ProteinName"
  colnames(input)[colnames(input) == "Protein.Accessions"] <- "ProteinName"
  colnames(input)[colnames(input) == "Master.Protein.Accessions"] <- "ProteinName"
  colnames(input)[colnames(input) == "X..Proteins"] <- "numProtein"
  colnames(input)[colnames(input) == "Sequence"] <- "PeptideSequence"
  colnames(input)[colnames(input) == "Annotated.Sequence"] <- "PeptideSequence"
  colnames(input)[colnames(input) == "Spectrum.File"] <- "Run"
  colnames(input)[colnames(input) == "Precursor.Area"] <- "Intensity"
  colnames(input)[colnames(input) == "Area"] <- "Intensity"

################################################
### 2. remove peptides which are used in more than one protein
### we assume to use unique peptide
################################################
  if (useNumProteinsColumn) {
    ## remove rows with #proteins is not 1
    input <- input[input[["numProtein"]] == "1", ]
    message("** Rows with #Proteins, which are not equal to 1, are removed.")
  }

  if (useUniquePeptide) {
    ## double check
    pepcount <- unique(input[, c("ProteinName", "PeptideSequence")])
    pepcount[["PeptideSequence"]] <- factor(pepcount$PeptideSequence)
    ## count how many proteins are assigned for each peptide
    structure <- aggregate(ProteinName ~., data=pepcount, length)
    remove_peptide <- structure[structure[["ProteinName"]] != 1, ]
    ## remove the peptides which are used in more than one protein
    if (length(remove_peptide[["Proteins"]] != 1) != 0) {
      input <- input[-which(input[["Sequence"]] %in% remove_peptide[["Sequence"]]), ]
      message("** Peptides, that are used in more than one proteins, are removed.")
    }
  }

################################################
### 3. remove the peptides including oxidation (M) sequence
################################################
  if (removeOxidationMpeptides) {
    remove_m_sequence <- unique(input[grep("Oxidation", input[["Modifications"]]), "Modifications"])
    if (length(remove_m_sequence) > 0) {
      input <- input[-which(input[["Modifications"]] %in% remove_m_sequence), ]
    }
    message("Peptides including oxidation(M) in the Modifications are removed.")
  }

##############################
### 4. remove multiple measurements per feature and run
##############################
  ## maximum or sum up abundances among intensities for identical features within one run
  input_sub <- dcast(ProteinName + PeptideSequence + Modifications + Charge ~ Run, data=input,
                     value.var="Intensity",
                     fun.aggregate=summaryforMultipleRows,
                     fill=NA_real_)
  ## reformat for long format
  input_sub <- melt(input_sub, id=c("ProteinName", "PeptideSequence", "Modifications", "Charge"))
  colnames(input_sub)[which(colnames(input_sub) %in%
                            c("variable", "value"))] <- c("Run", "Intensity")
  message("** Multiple measurements in a feature and a run are summarized by summaryforMultipleRows.")
  input <- input_sub

##############################
### 5. add annotation
##############################
  noruninfo <- setdiff(unique(input[["Run"]]), unique(annotation[["Run"]]))
  if (length(noruninfo) > 0) {
    stop(paste("** Annotation for Run :",
               paste(noruninfo, collapse = ", "),
               " are needed. Please update them in annotation file."))
  }

  input <- merge(input, annotation, by="Run", all=TRUE)
  ## add other required information
  input[["FragmentIon"]] <- NA
  input[["ProductCharge"]] <- NA
  input[["IsotopeLabelType"]] <- "L"
  input[["PeptideModifiedSequence"]] <- paste(input[["PeptideSequence"]],
                                              input[["Modifications"]], sep="_")
  input.final <- data.frame(
    "ProteinName" = input[["ProteinName"]],
    "PeptideModifiedSequence" = input[["PeptideModifiedSequence"]],
    "PrecursorCharge" = input[["Charge"]],
    "FragmentIon" = input[["FragmentIon"]],
    "ProductCharge" = input[["ProductCharge"]],
    "IsotopeLabelType" = input[["IsotopeLabelType"]],
    "Condition" = input[["Condition"]],
    "BioReplicate" = input[["BioReplicate"]],
    "Run" = input[["Run"]],
    "Intensity" = input[["Intensity"]])

  if (any(is.element(colnames(input), "Fraction"))) {
    input.final <- data.frame(input.final,
                              "Fraction" = input[["Fraction"]])
  }
  input <- input.final
  rm(input.final)

##############################
### 6. remove features which has 1 or 2 measurements across runs
##############################
  if (fewMeasurements=="remove") {
    ## it is the same across experiments. # measurement per feature.
    xtmp <- input[!is.na(input[["Intensity"]]) & input[["Intensity"]] > 0, ]
    xtmp[["feature"]] <- paste(xtmp[["PeptideModifiedSequence"]],
                               xtmp[["PrecursorCharge"]], sep="_")
    count_measure <- xtabs(~feature, xtmp)
    remove_feature_name <- count_measure[count_measure < 3]
    input$feature <- paste(input[["PeptideModifiedSequence"]],
                           input[["PrecursorCharge"]], sep="_")

    if (length(remove_feature_name) > 0) {
      input <- input[-which(input$feature %in% names(remove_feature_name)), ]
    }
    input <- input[, -which(colnames(input) %in% c("feature"))]
  }

##############################
### 7. remove proteins with only one peptide and charge per protein
##############################
  if (removeProtein_with1Peptide) {
    ## remove protein which has only one peptide
    input$feature <- paste(input[["PeptideModifiedSequence"]],
                           input[["PrecursorCharge"]],
                           input[["FragmentIon"]],
                           input[["ProductCharge"]],
                           sep="_")

    tmp <- unique(input[, c("ProteinName", "feature")])
    tmp$ProteinName <- factor(tmp[["ProteinName"]])
    count <- xtabs(~ ProteinName, data=tmp)
    lengthtotalprotein <- length(count)
    removepro <- names(count[count <= 1])
    if (length(removepro) > 0) {
      input <- input[-which(input[["ProteinName"]] %in% removepro), ]
      message(paste0("** ", length(removepro),
                     " proteins, which have only one feature in a protein, are removed among ",
                     lengthtotalprotein, " proteins."))
    }
    input <- input[, -which(colnames(input) %in% c("feature"))]
  }
  input[["ProteinName"]] <- input[["ProteinName"]]
  return(input)
}
