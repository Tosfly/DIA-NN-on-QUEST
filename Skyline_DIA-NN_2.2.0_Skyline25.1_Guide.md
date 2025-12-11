# Using Skyline 25.1 to Open and Visualize DIA-NN 2.2.0 Results  
*(example: 15 human plasma DIA runs from Orbitrap Ascend)*

This guide walks through, step by step, how to:

1. Prepare DIA-NN 2.2.0 outputs for Skyline  
2. Configure **Skyline 25.1** for Orbitrap Ascend DIA data  
3. Import the DIA-NN spectral library and report  
4. Import raw DIA files and extract chromatograms  
5. Inspect peaks and product ions (including a single y1⁺ ion) across multiple samples  

The examples use the following real file names:

- DIA-NN spectral library:  
  `15_plasma_samples_NUADC_Tuned_Lib.parquet.skyline.speclib`
- DIA-NN report:  
  `15_plasma_sample_report.parquet`
- DIA DIA raw files (15 runs):  
  `plasma_run_01.raw`, …, `plasma_run_15.raw` (names will be whatever you used in DIA-NN)

> **Assumptions**
> - You used **DIA-NN 2.2.0** to analyze Orbitrap Ascend DIA data.  
> - Your DIA-NN run used a standard tryptic search with carbamidomethyl (C, fixed) and variable Oxidation (M), Acetyl (N-term), Phospho (STY), GlyGly (K).  
> - You are using **Skyline 25.1** (release) on Windows.

---

## 0. Prepare your DIA-NN output folder for Skyline

Skyline’s DIA-NN import works best when the folder contains only the DIA-NN files that actually belong together.

1. Create a clean folder, e.g.  

   ```text
   D:\DIA-NN_to_Skyline\plasma_skyline_import\
   ```

2. Copy **exactly these two DIA-NN outputs** into that folder:

   ```text
   15_plasma_samples_NUADC_Tuned_Lib.parquet.skyline.speclib
   15_plasma_sample_report.parquet
   ```

3. Keep all other DIA-NN outputs (e.g. `*_first-pass.*`, `*_matrix.tsv`, PDFs) **outside** this folder to avoid confusing Skyline’s library builder.

You will also need your **raw DIA files** (15 plasma runs) in their usual location. You do *not* move them into this folder.

---

## 1. Start a new Skyline document

1. Launch **Skyline 25.1**.
2. On the start screen, choose **Blank document**, then click **OK**.

We will configure the document so that it matches the DIA-NN search.

---

## 2. Peptide Settings → Digestion

Menu: **Settings → Peptide Settings… → Digestion tab**

Set:

- **Enzyme**: `Trypsin [KR | P]`  
- **Max missed cleavages**: `1`  
- **Min. peptide length**: `7`  
- **Max. peptide length**: `30`  
- **Background proteome**: leave as **None** (for this QC-focused workflow)

Click **OK** or move to the **Modifications** tab next.

---

## 3. Peptide Settings → Modifications

Menu: **Settings → Peptide Settings… → Modifications tab**

Skyline now uses a single **Structural modifications** list where each mod can be marked as *Variable* or not (fixed).

### 3.1 Edit Structural modifications list

1. Click **Edit List…** next to **Structural modifications**.
2. In the **Edit Structural Modifications** dialog, make sure you have these entries:

**Fixed modification**

- **Carbamidomethyl (C)**  
  - Amino acid: `C`  
  - **Variable**: **unchecked** (this makes it fixed)  

**Variable modifications**

- **Oxidation (M)**  
  - Amino acid: `M`  
  - **Variable**: **checked**

- **Acetyl (Protein N-term)**  
  - Terminus: `N-term` / `Protein N-term`  
  - **Variable**: **checked**

- **Phospho (STY)**  
  - Amino acids: `S,T,Y`  
  - **Variable**: **checked**

- **GlyGly (K)** *(custom if not present)*  
  - If not in the list, click **Add…** and define:
    - **Name**: `GlyGly (K)` (any descriptive name is fine)
    - Amino acid: `K`
    - Monoisotopic mass shift: `114.04293`
    - (Optional) Formula: `H(6) C(4) N(2) O(2)`
    - **Variable**: **checked**

3. Click **OK** to return to the Modifications tab.

### 3.2 Activate these modifications for the document

Back in **Peptide Settings → Modifications**:

- Under **Structural modifications**, check:

  - `Carbamidomethyl (C)`
  - `Oxidation (M)`
  - `Acetyl (Protein N-term)`
  - `Phospho (STY)`
  - `GlyGly (K)`

- At the bottom:

  - **Max variable mods per peptide**: `3`

Click **OK** to save Peptide Settings.

---

## 4. Build the library from DIA-NN `.skyline.speclib`

We will now create a Skyline library based on the DIA-NN 2.2.0 outputs.

1. In Skyline, go to **File → Import → Peptide Search…**.
2. If asked, select **Build a spectral library from search results** and click **Next**.

### 4.1 Select the DIA-NN `.skyline.speclib`

1. On the **Build Spectral Library** page, click **Add Files…**.
2. Navigate to:

   ```text
   D:\DIA-NN_to_Skyline\plasma_skyline_import\
   ```

3. Select:

   ```text
   15_plasma_samples_NUADC_Tuned_Lib.parquet.skyline.speclib
   ```

4. Click **Open**.

Skyline will:

- Recognize this as a DIA-NN-compatible spectral library.
- Automatically look for `15_plasma_sample_report.parquet` in the same folder to pull RTs, q-values, and boundaries.

5. Choose a name/location for the Skyline library file (e.g. `plasma_diann.blib` in the same folder).
6. Click **Next** and let Skyline build the library.

If Skyline complains about missing or mismatched report files, re-check that only **these two** DIA-NN outputs are in the folder.

---

## 5. Configure decoy generation

Next, Skyline may show a page about **Decoys**.

- **Decoy generation method**: set to **None**.
- Ignore `Decoys per target` (it will be disabled or unused).

Because DIA-NN already handled FDR and decoys internally, Skyline does not need to generate its own decoys for this visualization workflow.

Click **Next**.

---

## 6. Configure Transition Settings (Filter & Library)

The wizard will open a **Configure Transition Settings** dialog. These settings control:

- Which precursors and product ions you will see.  
- How many transitions per precursor Skyline will keep.

### 6.1 Filter tab

On the **Filter** tab:

- **Precursor charges**: check

  - `2`
  - `3`  
  - (Optional) also check `4` if you expect some 4+ precursors

- **Ion types**: check

  - `y`  
  - (You can add `b` later if needed; starting with y-only is cleaner.)

- **Product charges**: check

  - `1`
  - `2`

- **Product ions from**:  

  - From: `3`  
  - To: `last ion`

This keeps y-ions from y3 to the last y-ion, which is a standard choice for DIA.

If you see fields for **Min m/z** and **Max m/z** here:

- **Min m/z**: `300`  
- **Max m/z**: `2000`  

(Aligns with the 300–2000 m/z precursor range used in DIA-NN.)

> **Note:** Do **not** check “Use DIA precursor window for exclusion” at this stage if your **Full-Scan → Isolation scheme** is `Results only` (we set that below). Skyline will warn you if you do.

### 6.2 Library tab

On the **Library** tab:

- Choose (wording may vary per UI):

  - **Pick**: `From spectral library` / `Filter by library`  
  - **Transitions per precursor**: `6`  
  - **Min product ions**: `6`

This tells Skyline:

- For each precursor, select the top 6 y-ions based on the DIA-NN spectral library, subject to your filters (ion type, charge, m/z).

Click **OK** to close **Configure Transition Settings**.

---

## 7. Configure Full-Scan (MS1 & MS/MS)

Now the wizard will show a **Configure Full-Scan Settings** dialog. These settings define how Skyline extracts chromatograms from the raw data.

You will configure both **MS1 filtering** and **MS/MS filtering** to match Orbitrap Ascend DIA results.

### 7.1 MS1 filtering

In the **MS1 filtering** area:

- **Isotope peaks included**: `Count`
- **Peaks**: `3`  (M, M+1, M+2)
- **Precursor mass analyzer**: `Centroided`

When you choose `Centroided`, the “Resolution” field becomes **Mass accuracy (ppm)**:

- **Mass accuracy**: `10`  

This is slightly wider than the 5–6 ppm recommended by DIA-NN in its log, giving Skyline a safe window for MS1 peak extraction.

### 7.2 MS/MS filtering

In the **MS/MS filtering** area:

- **Acquisition method**: `DIA`
- **Isolation scheme**: `Results only`

  - This tells Skyline to read the actual DIA windows from the raw files rather than from a hand-entered table.

- **Product mass analyzer**: `Centroided`
- **Mass accuracy (ppm)**: `10` or `15`  

  - Using `10` keeps MS2 extraction narrow but consistent with your high-resolution Orbitrap data.

### 7.3 Retention time filtering

At the bottom:

- **Retention time filtering**:

  - Select: `Use only scans within [ 2 ] minutes of MS/MS IDs`

This focuses extraction around the DIA-NN identifications (±2 min).

Click **OK** to close the Full-Scan configuration.

---

## 8. Add and import DIA raw files

Next step in the wizard: **Extract Chromatograms**.

You now choose which raw files to use and how many to process in parallel.

1. Skyline shows an **Extract Chromatograms** window.
2. In the file browser within this window, navigate to the folder containing your DIA raw files:

   ```text
   E:\data\plasma_DIA_runs\
   ```

3. Select **all 15 raw files**, e.g.:

   ```text
   plasma_run_01.raw
   plasma_run_02.raw
   ...
   plasma_run_15.raw
   ```

4. Click **Add** (or **Add All**) so they appear in the list of files to import.
5. In **Files to import simultaneously**, choose a safe number, e.g. `3` (3 raw files importing at the same time).  
   - If your machine is powerful, you can go higher; if modest, use `1`.

6. Click **OK** (or **Next/Finish**, depending on the wizard).

Skyline will now:

- Use the DIA-NN library and report to define the peptide/precursor targets.
- Extract MS1 and MS2 chromatograms for the top 6 y-ions per precursor from each raw run.
- Apply DIA-NN-derived RT/peak boundaries where possible.

This step can take some time for 15 DIA runs.

---

## 9. Quick sanity checks after import

Once Skyline has finished importing chromats:

1. On the **left**, the **Targets** tree should show:

   - Proteins
   - Peptides under each protein
   - Precursors and transitions under each peptide

2. On the **top toolbar**, you should see a **replicate dropdown** listing all 15 runs, e.g.:

   - `plasma_run_01`
   - `plasma_run_02`
   - …
   - `plasma_run_15`

3. Open the spectral library view:

   - **View → Spectral Libraries**
   - Select your library (`plasma_diann`).
   - Inspect a few spectra to confirm that modifications (Oxidation M, Phospho STY, etc.) are recognized.

---

## 10. Visualizing peaks for a protein across 15 runs

### 10.1 Basic per-peptide per-run view

1. In **Targets**:

   - Expand your protein of interest (e.g. `APOA1`).
   - Expand a peptide under it.
   - Click on a **precursor** (e.g. 2+).

2. Make sure a chromatogram graph is visible:

   - **View → Chromatograms → Transitions**.

3. In the chromatogram graph:

   - Right-click → ensure **Peak boundaries** is checked.
   - In the toolbar above the chromatogram, enable **Auto-Zoom → Best Peak**.

4. To inspect this peptide’s product ions in each sample:

   - Use the **replicate dropdown** at the top of the Skyline window.
   - Select `plasma_run_01`, check the chromatogram.
   - Then select `plasma_run_02`, etc., until `plasma_run_15`.

This gives you a clean, sequential view of the same peptide’s transitions in each run.

---

## 11. Visualizing a single product ion (e.g. y1⁺) across all samples

Sometimes you want to track one specific fragment ion (e.g. y1⁺) across all runs. Here is how.

### 11.1 Ensure the y1⁺ transition is included

1. In **Targets**:

   - Expand **Protein → Peptide → Precursor**.
   - Right-click the **precursor** → **Pick Children…**.

2. In the list of transitions:

   - Find the fragment ion **`y1`** (charge `1+`).
   - Check the box for `y1`.
   - Click **OK**.

Now y1⁺ will be part of the transitions for that precursor.

### 11.2 Show only y1⁺ in the chromatogram

1. In **Targets**, click on the **precursor** again.
2. In the chromatogram legend (right side of the graph):

   - Find `y1` in the list of transitions.
   - Click it until **only `y1` remains visible** (others hidden or greyed out).

3. Ensure:

   - **Auto-Zoom → Best Peak** is on.
   - **Peak boundaries** are displayed.

The chromatogram now shows **just the y1⁺** trace for the currently selected replicate.

### 11.3 Step through the 15 samples

To see that same y1⁺ in each run:

1. Use the **replicate dropdown** at the top of Skyline:

   - Choose `plasma_run_01`: inspect y1⁺.
   - Choose `plasma_run_02`: inspect again.
   - Continue through all 15 runs.

This gives you an aligned mental picture of that y1⁺ peak in each sample.

> **Tip:**  
> For a numerical RT/area comparison across runs for y1⁺, use **Document Grid** (next section).

---

## 12. Getting numeric RT and area for a specific transition across runs

1. Open **View → Document Grid**.
2. In the bottom-left of the Document Grid, select a report:

   - e.g. **Transition Results**.

3. Filter the grid:

   - Filter **Protein** to your protein of interest (right-click column header → Filter…).  
   - Filter **Peptide** if necessary.  
   - Filter **Transition** (or Fragment Ion) to `y1` (exact label might be `y1+`).

You will now see one row per replicate for that exact y1⁺ transition, including:

- **Replicate** name
- **Retention Time**
- **Start Time**
- **End Time**
- **Area**

This gives a precise, aligned view of that product ion’s peak in all samples.

You can export this table for downstream plotting (e.g. overlay RT drift across runs).

---

## 13. Common warnings and how to handle them

### 13.1 “Cannot use DIA window for precursor exclusion…”

If you see:

> `Cannot use DIA window for precursor exclusion when isolation scheme does not contain prespecified windows…`

That means:

- In **Transition Settings → Filter**, `Use DIA precursor window for exclusion` was checked.
- In **Transition Settings → Full-Scan → MS/MS filtering**, the **Isolation scheme** is `Results only`.

**Fix:**

1. Go to **Settings → Transition Settings… → Filter tab**.
2. UNcheck `Use DIA precursor window for exclusion`.
3. Click **OK**.

You cannot use that option with `Results only`. This does **not** affect your main workflow; it only toggles a minor transition exclusion rule.

---

## 14. Summary of recommended Skyline 25.1 settings (Orbitrap Ascend + DIA-NN 2.2.0)

**Peptide Settings → Digestion**

- Enzyme: `Trypsin [KR | P]`
- Max missed cleavages: `1`
- Min peptide length: `7`
- Max peptide length: `30`
- Background proteome: `None` (for QC)

**Peptide Settings → Modifications**

- Structural mods checked:
  - `Carbamidomethyl (C)` (fixed; Variable unchecked)
  - `Oxidation (M)` (variable)
  - `Acetyl (Protein N-term)` (variable)
  - `Phospho (STY)` (variable)
  - `GlyGly (K)` (variable)
- Max variable mods per peptide: `3`

**Transition Settings → Full-Scan**

- MS1 filtering:
  - Isotope peaks included: `Count`
  - Peaks: `3`
  - Precursor mass analyzer: `Centroided`
  - Mass accuracy: `10 ppm`

- MS/MS filtering:
  - Acquisition method: `DIA`
  - Isolation scheme: `Results only`
  - Product mass analyzer: `Centroided`
  - Mass accuracy: `10–15 ppm` (10 ppm recommended)

- Retention time filtering:
  - Use only scans within `2` minutes of MS/MS IDs

**Transition Settings → Filter**

- Precursor charges: `2, 3` (optional: `4`)
- Ion types: `y` (add `b` later if desired)
- Product charges: `1, 2`
- Product ions from: `3` to `last ion`
- Min m/z: `300`
- Max m/z: `2000`
- *Do not* check `Use DIA precursor window for exclusion` with `Results only`.

**Transition Settings → Library**

- Pick transitions from: `From spectral library` / `Filter by library`
- Product ions: `6`
- Min product ions: `6`

**Decoy generation**

- Decoy generation method: `None`

With this configuration, Skyline 25.1 will faithfully visualize your **DIA-NN 2.2.0** results and let you inspect peaks and product ions (including individual fragments like y1⁺) across all samples.
