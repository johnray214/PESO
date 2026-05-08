<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Font;
use Symfony\Component\HttpFoundation\StreamedResponse;

class LmaController extends Controller
{
    /** Header fill (matches stephen-25LMA template) */
    private const HEADER_FILL = 'C9DAF8';
    private const TOTAL_FILL  = 'C9DAF8';
    private const FONT_NAME   = 'Calibri';
    private const FONT_SIZE   = 12;

    public function generateExcel(Request $request)
    {
        $request->validate([
            'summary'              => 'required|array',
            'summary.period'       => 'required|string',
            'summary.localTotal'   => 'required|numeric',
            'summary.overseasTotal'=> 'required|numeric',
            'summary.grandTotal'   => 'required|numeric',
            'summary.topPositions' => 'required|array',
        ]);

        $s = $request->input('summary');

        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('LMA ' . substr($s['period'], 0, 24));

        // Default font for the whole workbook
        $spreadsheet->getDefaultStyle()->getFont()
            ->setName(self::FONT_NAME)
            ->setSize(self::FONT_SIZE);

        // Column widths (slightly compressed to match reference layout)
        $widths = ['A'=>8, 'B'=>19, 'C'=>11, 'D'=>12, 'E'=>13, 'F'=>12, 'G'=>18, 'H'=>11, 'I'=>11];
        foreach ($widths as $col => $w) {
            $sheet->getColumnDimension($col)->setWidth($w);
        }

        $row = 1;

        // ── Title block ──
        $period = $s['period'];
        $sheet->setCellValue("A{$row}", "Labor Market Analysis: {$period}");
        $sheet->mergeCells("A{$row}:I{$row}");
        $this->applyStyle($sheet, "A{$row}", [
            'font'      => ['bold' => true, 'size' => 16],
            'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER],
        ]);
        $sheet->getRowDimension($row)->setRowHeight(24);
        $row++;

        $sheet->setCellValue("A{$row}", 'PESO SANTIAGO CITY');
        $sheet->mergeCells("A{$row}:I{$row}");
        $this->applyStyle($sheet, "A{$row}", [
            'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER],
        ]);
        $row++;

        // ── I. INTRODUCTION ──
        $sheet->setCellValue("A{$row}", 'I. INTRODUCTION');
        $row++;
        $introI = "This {$period}, the Public Employment Service Office (PESO) Santiago City had served programs and services such as Job Solicitation, Labor Market Information, Referral and Placement thru regular wage referral, recruitment activities (SRA/LRA), Job Fair, and other PESO employment facilitation programs.";
        $sheet->setCellValue("A{$row}", $introI);
        $sheet->mergeCells("A{$row}:I{$row}");
        $sheet->getStyle("A{$row}")->getAlignment()->setWrapText(true)->setVertical(Alignment::VERTICAL_TOP);
        $sheet->getRowDimension($row)->setRowHeight(48);
        $row += 2;

        // ── II. PUBLIC EMPLOYMENT SERVICES ──
        $sheet->setCellValue("A{$row}", 'II. PUBLIC EMPLOYMENT SERVICES THROUGH PESO/PEIS');
        $row++;

        $localPct    = $s['grandTotal'] > 0 ? round(($s['localTotal']    / $s['grandTotal']) * 100) : 0;
        $overseasPct = $s['grandTotal'] > 0 ? round(($s['overseasTotal'] / $s['grandTotal']) * 100) : 0;
        $majorityKind  = $s['localTotal'] >= $s['overseasTotal'] ? 'local' : 'overseas';
        $majorityCount = $s['localTotal'] >= $s['overseasTotal'] ? $s['localTotal'] : $s['overseasTotal'];
        $majorityPct   = $s['localTotal'] >= $s['overseasTotal'] ? $localPct : $overseasPct;

        $servicesIntro = 'A total of ' . number_format($s['grandTotal']) . ' job vacancies were solicited and promoted to our jobseekers. '
            . 'Table 1 shows that majority of job vacancies solicited were from ' . $majorityKind . ' employment, '
            . 'with a total of ' . number_format($majorityCount) . " or {$majorityPct}%.";
        $sheet->setCellValue("A{$row}", $servicesIntro);
        $sheet->mergeCells("A{$row}:I{$row}");
        $sheet->getStyle("A{$row}")->getAlignment()->setWrapText(true)->setVertical(Alignment::VERTICAL_TOP);
        $sheet->getRowDimension($row)->setRowHeight(36);
        $row += 2;

        // ── TABLE 1 ──
        $sheet->setCellValue("A{$row}", 'Table 1. Job vacancies solicited');
        $this->applyStyle($sheet, "A{$row}", ['font' => ['bold' => true]]);
        $row++;

        $t1Start = $row;
        $this->renderTable1Header($sheet, $row);
        $row++;
        $this->renderTable1DataRow($sheet, $row, 'Local',    $s['localTotal'],    $s['grandTotal']);
        $row++;
        $this->renderTable1DataRow($sheet, $row, 'Overseas', $s['overseasTotal'], $s['grandTotal']);
        $row++;
        $this->renderTable1DataRow($sheet, $row, 'Total',    $s['grandTotal'],    $s['grandTotal'], true);
        $this->applyOuterBorder($sheet, "A{$t1Start}:I{$row}");
        $row += 2;

        // ── TABLE 2: Registered Applicants ──
        $t2 = $s['table2'] ?? null;
        if ($t2 && ($t2['total'] ?? 0) > 0) {
            $regIntro = 'Through our PESO Employment Information System (PEIS), we had ' . number_format($t2['total'])
                . ' registered applicants and majority of them were '
                . (($t2['female'] ?? 0) >= ($t2['male'] ?? 0) ? 'females' : 'males')
                . ' as shown in table 2. They were assisted for their respective employment concerns like referral for Job Fair, SRA/LRA and other special programs.';
            $sheet->setCellValue("A{$row}", $regIntro);
            $sheet->mergeCells("A{$row}:I{$row}");
            $sheet->getStyle("A{$row}")->getAlignment()->setWrapText(true)->setVertical(Alignment::VERTICAL_TOP);
            $sheet->getRowDimension($row)->setRowHeight(36);
            $row += 2;

            $sheet->setCellValue("A{$row}", 'Table 2. Registered Applicants');
            $this->applyStyle($sheet, "A{$row}", ['font' => ['bold' => true]]);
            $row++;

            $t2Start = $row;
            $this->renderGenderTableHeader($sheet, $row, 'Number of registered applicants');
            $row++;
            $this->renderGenderRow($sheet, $row, 'Male',   $t2['male'],   $t2['total']);
            $row++;
            $this->renderGenderRow($sheet, $row, 'Female', $t2['female'], $t2['total']);
            $row++;
            $this->renderGenderRow($sheet, $row, 'Total',  $t2['total'],  $t2['total'], true);
            $this->applyOuterBorder($sheet, "A{$t2Start}:I{$row}");
            $row += 2;
        }

        // ── TABLE 3: Referred & Placed ──
        $t3 = $s['table3'] ?? null;
        if ($t3 && (($t3['ref']['total'] ?? 0) > 0)) {
            $placedTotal = $t3['placed']['total'] ?? 0;
            $refTotal    = $t3['ref']['total']    ?? 1;
            $placedRate  = $refTotal ? round(($placedTotal / $refTotal) * 100, 2) : 0;

            $t3Intro = 'In our placement assistance, a total of ' . number_format($refTotal) . ' applicants were referred '
                . 'and ' . number_format($placedTotal) . ' were placed (placement rate: ' . $placedRate . '%). '
                . 'Table 3 below shows the distribution by gender and work location.';
            $sheet->setCellValue("A{$row}", $t3Intro);
            $sheet->mergeCells("A{$row}:I{$row}");
            $sheet->getStyle("A{$row}")->getAlignment()->setWrapText(true)->setVertical(Alignment::VERTICAL_TOP);
            $sheet->getRowDimension($row)->setRowHeight(36);
            $row += 2;

            $sheet->setCellValue("A{$row}", 'Table 3. Referred and Placed Applicants by Gender and by Work Location');
            $this->applyStyle($sheet, "A{$row}", ['font' => ['bold' => true]]);
            $row++;

            $t3Start = $row;
            $this->renderTable3Header($sheet, $row);
            $row += 2;
            $this->renderTable3Row($sheet, $row, 'Male',   $t3, 'male',   $refTotal);
            $row++;
            $this->renderTable3Row($sheet, $row, 'Female', $t3, 'female', $refTotal);
            $row++;
            $this->renderTable3TotalRow($sheet, $row, $t3, $refTotal);
            $this->applyOuterBorder($sheet, "A{$t3Start}:I{$row}");
            $row += 2;
        }

        // ── TABLE 4: Top Positions ──
        $t4Intro = 'As presented in Table 4, the data captures the most commonly solicited positions for the period across local and overseas employment.';
        $sheet->setCellValue("A{$row}", $t4Intro);
        $sheet->mergeCells("A{$row}:I{$row}");
        $sheet->getStyle("A{$row}")->getAlignment()->setWrapText(true)->setVertical(Alignment::VERTICAL_TOP);
        $sheet->getRowDimension($row)->setRowHeight(28);
        $row += 2;

        $sheet->setCellValue("A{$row}", 'Table 4. Top Commonly Solicited Job Vacancies for Local and Overseas Employment');
        $this->applyStyle($sheet, "A{$row}", ['font' => ['bold' => true]]);
        $row += 2;

        $t4Start = $row;
        $this->renderTable4Header($sheet, $row);
        $row++;

        $positions  = $s['topPositions'] ?? [];
        $grandTotal = $s['grandTotal'];

        foreach ($positions as $idx => $pos) {
            $num = $idx + 1;
            $sheet->setCellValue("A{$row}", $num);
            $sheet->setCellValue("B{$row}", $pos['name']);
            $sheet->mergeCells("B{$row}:C{$row}");
            $sheet->setCellValue("D{$row}", $pos['local']);
            $sheet->setCellValue("E{$row}", $pos['overseas']);
            $sheet->setCellValue("F{$row}", $pos['total']);
            $sheet->setCellValue("G{$row}", $pos['industry'] ?? '');
            $sheet->mergeCells("G{$row}:H{$row}");
            $pct = $grandTotal > 0 ? $pos['total'] / $grandTotal : 0;
            $sheet->setCellValue("I{$row}", $pct);
            $this->styleNumericRow($sheet, $row);

            // Subtotal after Top 5
            if ($idx === 4) {
                $row++;
                $top5 = array_slice($positions, 0, 5);
                $sumLocal    = array_sum(array_column($top5, 'local'));
                $sumOverseas = array_sum(array_column($top5, 'overseas'));
                $sumTotal    = array_sum(array_column($top5, 'total'));
                $sheet->setCellValue("B{$row}", 'Subtotal-Top 5');
                $sheet->mergeCells("B{$row}:C{$row}");
                $sheet->setCellValue("D{$row}", $sumLocal);
                $sheet->setCellValue("E{$row}", $sumOverseas);
                $sheet->setCellValue("F{$row}", $sumTotal);
                $pct5 = $grandTotal > 0 ? $sumTotal / $grandTotal : 0;
                $sheet->setCellValue("I{$row}", $pct5);
                $this->styleNumericRow($sheet, $row);
                $this->applyStyle($sheet, "A{$row}:I{$row}", ['font' => ['bold' => true]]);

                $row++;
                $sheet->setCellValue("A{$row}", 'Top 6 and below');
                $sheet->mergeCells("A{$row}:C{$row}");
            }
            $row++;
        }

        // Top 6-10 subtotal
        if (count($positions) > 5) {
            $tail = array_slice($positions, 5, 5);
            if (!empty($tail)) {
                $sumLocal    = array_sum(array_column($tail, 'local'));
                $sumOverseas = array_sum(array_column($tail, 'overseas'));
                $sumTotal    = array_sum(array_column($tail, 'total'));
                $sheet->setCellValue("A{$row}", '(Top 6 -10)');
                $sheet->mergeCells("A{$row}:C{$row}");
                $sheet->setCellValue("D{$row}", $sumLocal);
                $sheet->setCellValue("E{$row}", $sumOverseas);
                $sheet->setCellValue("F{$row}", $sumTotal);
                $pct = $grandTotal > 0 ? $sumTotal / $grandTotal : 0;
                $sheet->setCellValue("I{$row}", $pct);
                $this->styleNumericRow($sheet, $row);
                $this->applyStyle($sheet, "A{$row}:I{$row}", ['font' => ['bold' => true]]);
                $row++;
            }
        }

        // Others row
        if (!empty($s['others'])) {
            $others = $s['others'];
            $sheet->setCellValue("A{$row}", 'Others: ' . ($others['names'] ?? ''));
            $sheet->mergeCells("A{$row}:C{$row}");
            $sheet->getStyle("A{$row}")->getAlignment()->setWrapText(true);
            $sheet->setCellValue("D{$row}", $others['local'] ?? 0);
            $sheet->setCellValue("E{$row}", $others['overseas'] ?? 0);
            $sheet->setCellValue("F{$row}", $others['total'] ?? 0);
            $sheet->mergeCells("G{$row}:H{$row}");
            $othersPct = $grandTotal > 0 ? (($others['total'] ?? 0) / $grandTotal) : 0;
            $sheet->setCellValue("I{$row}", $othersPct);
            $this->styleNumericRow($sheet, $row);
            $row++;
        }

        // Grand Total row
        $sheet->setCellValue("A{$row}", 'Grand Total');
        $sheet->mergeCells("A{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", $s['localTotal']);
        $sheet->setCellValue("E{$row}", $s['overseasTotal']);
        $sheet->setCellValue("F{$row}", $s['grandTotal']);
        $sheet->mergeCells("G{$row}:H{$row}");
        $sheet->setCellValue("I{$row}", 1.0);
        $this->styleNumericRow($sheet, $row);
        $this->applyStyle($sheet, "A{$row}:I{$row}", [
            'font' => ['bold' => true],
            'fill' => ['type' => Fill::FILL_SOLID, 'color' => self::TOTAL_FILL],
        ]);
        $this->applyBorders($sheet, "A{$row}:I{$row}");
        $this->applyOuterBorder($sheet, "A{$t4Start}:I{$row}");
        $row += 2;

        // ── III. LABOR MARKET INFORMATION ──
        $sheet->setCellValue("A{$row}", 'III. LABOR MARKET INFORMATION');
        $row++;

        $lmiCount = $s['lmiInstitutions'] ?? 0;
        $lmiText  = 'In our Labor Market Information (LMI), we have reached individuals through the participation of '
            . number_format($lmiCount) . ' institutions from various sectors in the private, public and academe. '
            . 'They were provided the updates and new program innovations through flyers, symposiums and ads in our social media platforms.';
        $sheet->setCellValue("A{$row}", $lmiText);
        $sheet->mergeCells("A{$row}:I{$row}");
        $sheet->getStyle("A{$row}")->getAlignment()->setWrapText(true)->setVertical(Alignment::VERTICAL_TOP);
        $sheet->getRowDimension($row)->setRowHeight(48);
        $row += 2;

        $sheet->setCellValue("A{$row}", 'Table 5. Individual and Institutions Reached');
        $this->applyStyle($sheet, "A{$row}", ['font' => ['bold' => true]]);
        $row++;

        $t5Start = $row;
        // Table 5 two-row header
        $sheet->setCellValue("A{$row}", 'Institutions Reached');
        $sheet->mergeCells("A{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", 'Individuals Reached');
        $sheet->mergeCells("D{$row}:I{$row}");
        $this->applyHeaderStyle($sheet, "A{$row}:I{$row}");
        $row++;

        $sheet->setCellValue("A{$row}", 'No.');
        $sheet->setCellValue("B{$row}", 'Partner agencies');
        $sheet->mergeCells("B{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", 'Male');
        $sheet->setCellValue("E{$row}", 'Female');
        $sheet->mergeCells("E{$row}:F{$row}");
        $sheet->setCellValue("G{$row}", 'Youth');
        $sheet->setCellValue("H{$row}", 'Non-Youth');
        $sheet->mergeCells("H{$row}:I{$row}");
        $this->applyHeaderStyle($sheet, "A{$row}:I{$row}");
        $row++;

        // Use registered totals for individuals reached
        $male        = $s['table2']['male']     ?? 0;
        $female      = $s['table2']['female']   ?? 0;
        $youth       = $s['table2']['youth']    ?? 0;
        $nonYouth    = $s['table2']['nonYouth'] ?? 0;
        $totalReach  = $male + $female;
        $totalAge    = $youth + $nonYouth;

        $sheet->setCellValue("A{$row}", $lmiCount);
        $sheet->setCellValue("B{$row}", 'Public & Private Agencies');
        $sheet->mergeCells("B{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", $male);
        $sheet->setCellValue("E{$row}", $female);
        $sheet->mergeCells("E{$row}:F{$row}");
        $sheet->setCellValue("G{$row}", $youth);
        $sheet->setCellValue("H{$row}", $nonYouth);
        $sheet->mergeCells("H{$row}:I{$row}");
        $this->applyBorders($sheet, "A{$row}:I{$row}");
        foreach (['A','D','E','G','H'] as $col) {
            $sheet->getStyle("{$col}{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
            $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('#,##0');
        }
        $row++;

        if ($totalReach > 0 || $totalAge > 0) {
            $sheet->setCellValue("D{$row}", $totalReach > 0 ? $male / $totalReach : 0);
            $sheet->setCellValue("E{$row}", $totalReach > 0 ? $female / $totalReach : 0);
            $sheet->mergeCells("E{$row}:F{$row}");
            $sheet->setCellValue("G{$row}", $totalAge > 0 ? $youth / $totalAge : 0);
            $sheet->setCellValue("H{$row}", $totalAge > 0 ? $nonYouth / $totalAge : 0);
            $sheet->mergeCells("H{$row}:I{$row}");
            foreach (['D','E','G','H'] as $col) {
                $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('0.00%');
                $sheet->getStyle("{$col}{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
                $sheet->getStyle("{$col}{$row}")->getFont()->setBold(true);
            }
            $this->applyBorders($sheet, "A{$row}:I{$row}");
            $row++;

            // Total row spanning gender + age summaries
            $sheet->setCellValue("D{$row}", $totalReach);
            $sheet->mergeCells("D{$row}:F{$row}");
            $sheet->setCellValue("G{$row}", $totalAge ?: $totalReach);
            $sheet->mergeCells("G{$row}:I{$row}");
            foreach (['D','G'] as $col) {
                $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('#,##0');
                $sheet->getStyle("{$col}{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
                $sheet->getStyle("{$col}{$row}")->getFont()->setBold(true);
            }
            $this->applyBorders($sheet, "A{$row}:I{$row}");
            $row++;
        }
        $t5End = $row - 1;
        $this->applyOuterBorder($sheet, "A{$t5Start}:I{$t5End}");
        $row++;

        // ── V. SUMMARY, ANALYSIS AND CONCLUSION ──
        $sheet->setCellValue("A{$row}", 'V. SUMMARY, ANALYSIS AND CONCLUSION');
        $this->applyStyle($sheet, "A{$row}", ['font' => ['bold' => true]]);
        $row++;

        $bullets = $this->buildSummaryBullets($s, $localPct, $overseasPct);
        foreach ($bullets as $b) {
            $sheet->setCellValue("A{$row}", '•');
            $sheet->getStyle("A{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER)->setVertical(Alignment::VERTICAL_TOP);
            $sheet->setCellValue("B{$row}", $b);
            $sheet->mergeCells("B{$row}:I{$row}");
            $sheet->getStyle("B{$row}")->getAlignment()->setWrapText(true)->setVertical(Alignment::VERTICAL_TOP);
            $sheet->getRowDimension($row)->setRowHeight(48);
            $row++;
        }
        $row += 2;

        // ── Signatures ──
        $sheet->setCellValue("A{$row}", 'Reviewed by:');
        $sheet->setCellValue("F{$row}", 'Noted:');
        $row += 4;
        $sheet->setCellValue("A{$row}", 'ATTY. NIKKI JANE S. ISLA');
        $sheet->setCellValue("F{$row}", 'ATTY. ALYSSA SHEENA P. TAN, CPA');
        $this->applyStyle($sheet, "A{$row}", ['font' => ['bold' => true, 'underline' => Font::UNDERLINE_SINGLE]]);
        $this->applyStyle($sheet, "F{$row}", ['font' => ['bold' => true, 'underline' => Font::UNDERLINE_SINGLE]]);
        $row++;
        $sheet->setCellValue("A{$row}", 'OIC-PESO Manager');
        $sheet->setCellValue("F{$row}", 'City Mayor');

        // ── Output ──
        $filename = 'LMA_Report_' . preg_replace('/\s+/', '_', $s['period']) . '.xlsx';

        $response = new StreamedResponse(function () use ($spreadsheet) {
            $writer = new Xlsx($spreadsheet);
            $writer->save('php://output');
        });

        $response->headers->set('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        $response->headers->set('Content-Disposition', "attachment; filename=\"{$filename}\"");
        $response->headers->set('Cache-Control', 'max-age=0');

        return $response;
    }

    /* ────────────────────────────────────────────────────────────
       Table-1 helpers
       ──────────────────────────────────────────────────────────── */

    private function renderTable1Header($sheet, int $row): void
    {
        $sheet->setCellValue("A{$row}", 'Nature of Vacancy');
        $sheet->mergeCells("A{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", 'No. of Vacancies Solicited');
        $sheet->mergeCells("D{$row}:F{$row}");
        $sheet->setCellValue("G{$row}", 'Percentage');
        $sheet->mergeCells("G{$row}:I{$row}");
        $this->applyHeaderStyle($sheet, "A{$row}:I{$row}");
    }

    private function renderTable1DataRow($sheet, int $row, string $label, $count, $grandTotal, bool $bold = false): void
    {
        $sheet->setCellValue("A{$row}", $label);
        $sheet->mergeCells("A{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", $count);
        $sheet->mergeCells("D{$row}:F{$row}");
        $frac = $grandTotal > 0 ? $count / $grandTotal : 0;
        $sheet->setCellValue("G{$row}", $frac);
        $sheet->mergeCells("G{$row}:I{$row}");
        $sheet->getStyle("D{$row}")->getNumberFormat()->setFormatCode('#,##0');
        $sheet->getStyle("G{$row}")->getNumberFormat()->setFormatCode('0.00%');
        $sheet->getStyle("A{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_LEFT);
        foreach (['D','G'] as $col) {
            $sheet->getStyle("{$col}{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        }
        $this->applyBorders($sheet, "A{$row}:I{$row}");
        if ($bold) {
            $this->applyStyle($sheet, "A{$row}:I{$row}", ['font' => ['bold' => true]]);
        }
    }

    /* ────────────────────────────────────────────────────────────
       Table-2 helpers (gender table)
       ──────────────────────────────────────────────────────────── */

    private function renderGenderTableHeader($sheet, int $row, string $countLabel): void
    {
        $sheet->setCellValue("A{$row}", 'Gender');
        $sheet->mergeCells("A{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", $countLabel);
        $sheet->mergeCells("D{$row}:F{$row}");
        $sheet->setCellValue("G{$row}", 'Percentage');
        $sheet->mergeCells("G{$row}:I{$row}");
        $this->applyHeaderStyle($sheet, "A{$row}:I{$row}");
    }

    private function renderGenderRow($sheet, int $row, string $label, $count, $total, bool $bold = false): void
    {
        $sheet->setCellValue("A{$row}", $label);
        $sheet->mergeCells("A{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", $count);
        $sheet->mergeCells("D{$row}:F{$row}");
        $frac = $total > 0 ? $count / $total : 0;
        $sheet->setCellValue("G{$row}", $frac);
        $sheet->mergeCells("G{$row}:I{$row}");
        $sheet->getStyle("D{$row}")->getNumberFormat()->setFormatCode('#,##0');
        $sheet->getStyle("G{$row}")->getNumberFormat()->setFormatCode('0.00%');
        $sheet->getStyle("A{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_LEFT);
        foreach (['D','G'] as $col) {
            $sheet->getStyle("{$col}{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        }
        $this->applyBorders($sheet, "A{$row}:I{$row}");
        if ($bold) {
            $this->applyStyle($sheet, "A{$row}:I{$row}", ['font' => ['bold' => true]]);
        }
    }

    /* ────────────────────────────────────────────────────────────
       Table-3 helpers (referred & placed)
       ──────────────────────────────────────────────────────────── */

    private function renderTable3Header($sheet, int $row): void
    {
        $r1 = $row;
        $r2 = $row + 1;
        $sheet->setCellValue("A{$r1}", 'Gender');
        $sheet->mergeCells("A{$r1}:B{$r2}");
        $sheet->setCellValue("C{$r1}", 'REFERRED');
        $sheet->mergeCells("C{$r1}:C{$r2}");
        $sheet->setCellValue("D{$r1}", 'PLACED');
        $sheet->mergeCells("D{$r1}:D{$r2}");
        $sheet->setCellValue("E{$r1}", 'PLACEMENT Rate');
        $sheet->mergeCells("E{$r1}:E{$r2}");
        $sheet->setCellValue("F{$r1}", 'PLACED Distribution by Work Location');
        $sheet->mergeCells("F{$r1}:I{$r1}");
        $sheet->setCellValue("F{$r2}", 'Local');
        $sheet->setCellValue("G{$r2}", 'Rate (%)');
        $sheet->setCellValue("H{$r2}", 'Overseas');
        $sheet->setCellValue("I{$r2}", 'Rate (%)');
        $this->applyHeaderStyle($sheet, "A{$r1}:I{$r1}");
        $this->applyHeaderStyle($sheet, "A{$r2}:I{$r2}");
        foreach ([$r1, $r2] as $r) {
            $sheet->getStyle("A{$r}:I{$r}")->getAlignment()->setVertical(Alignment::VERTICAL_CENTER)->setWrapText(true);
        }
    }

    private function renderTable3Row($sheet, int $row, string $label, array $t3, string $key, $refTotal): void
    {
        $sheet->setCellValue("A{$row}", $label);
        $sheet->mergeCells("A{$row}:B{$row}");
        $sheet->setCellValue("C{$row}", $t3['ref'][$key]      ?? 0);
        $sheet->setCellValue("D{$row}", $t3['placed'][$key]   ?? 0);
        $placed = $t3['placed'][$key] ?? 0;
        $sheet->setCellValue("E{$row}", $refTotal > 0 ? $placed / $refTotal : 0);
        $sheet->setCellValue("F{$row}", $t3['placedLocal'][$key] ?? 0);
        $sheet->setCellValue("G{$row}", $refTotal > 0 ? ($t3['placedLocal'][$key] ?? 0) / $refTotal : 0);
        $sheet->setCellValue("H{$row}", $t3['placedOverseas'][$key] ?? 0);
        $sheet->setCellValue("I{$row}", $refTotal > 0 ? ($t3['placedOverseas'][$key] ?? 0) / $refTotal : 0);
        foreach (['C','D','F','H'] as $col) {
            $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('#,##0');
            $sheet->getStyle("{$col}{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        }
        foreach (['E','G','I'] as $col) {
            $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('0.00%');
            $sheet->getStyle("{$col}{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        }
        $sheet->getStyle("A{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_LEFT);
        $this->applyBorders($sheet, "A{$row}:I{$row}");
    }

    private function renderTable3TotalRow($sheet, int $row, array $t3, $refTotal): void
    {
        $sheet->setCellValue("A{$row}", 'Total');
        $sheet->mergeCells("A{$row}:B{$row}");
        $sheet->setCellValue("C{$row}", $refTotal);
        $sheet->setCellValue("D{$row}", $t3['placed']['total'] ?? 0);
        $placedTotal = $t3['placed']['total'] ?? 0;
        $sheet->setCellValue("E{$row}", $refTotal > 0 ? $placedTotal / $refTotal : 0);
        $sheet->setCellValue("F{$row}", $t3['placedLocal']['total']    ?? 0);
        $sheet->setCellValue("G{$row}", $refTotal > 0 ? ($t3['placedLocal']['total']    ?? 0) / $refTotal : 0);
        $sheet->setCellValue("H{$row}", $t3['placedOverseas']['total'] ?? 0);
        $sheet->setCellValue("I{$row}", $refTotal > 0 ? ($t3['placedOverseas']['total'] ?? 0) / $refTotal : 0);
        foreach (['C','D','F','H'] as $col) {
            $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('#,##0');
            $sheet->getStyle("{$col}{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        }
        foreach (['E','G','I'] as $col) {
            $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('0.00%');
            $sheet->getStyle("{$col}{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        }
        $sheet->getStyle("A{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_LEFT);
        $this->applyStyle($sheet, "A{$row}:I{$row}", ['font' => ['bold' => true]]);
        $this->applyBorders($sheet, "A{$row}:I{$row}");
    }

    /* ────────────────────────────────────────────────────────────
       Table-4 helpers
       ──────────────────────────────────────────────────────────── */

    private function renderTable4Header($sheet, int $row): void
    {
        $sheet->setCellValue("A{$row}", 'Position');
        $sheet->mergeCells("A{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", 'Local');
        $sheet->setCellValue("E{$row}", 'Overseas');
        $sheet->setCellValue("F{$row}", 'Total');
        $sheet->setCellValue("G{$row}", 'Type of Industries');
        $sheet->mergeCells("G{$row}:H{$row}");
        $sheet->setCellValue("I{$row}", 'Percentage');
        $this->applyHeaderStyle($sheet, "A{$row}:I{$row}");
    }

    private function styleNumericRow($sheet, int $row): void
    {
        foreach (['D','E','F'] as $col) {
            $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('#,##0');
            $sheet->getStyle("{$col}{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        }
        $sheet->getStyle("I{$row}")->getNumberFormat()->setFormatCode('0.00%');
        $sheet->getStyle("I{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        $sheet->getStyle("A{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        $this->applyBorders($sheet, "A{$row}:I{$row}");
    }

    /* ────────────────────────────────────────────────────────────
       Summary bullets
       ──────────────────────────────────────────────────────────── */

    private function buildSummaryBullets(array $s, int $localPct, int $overseasPct): array
    {
        $bullets = [];
        $period  = $s['period'];
        $bullets[] = "In our Job solicitation through Job Fair, Special/Local Recruitment Activity and Company Monitoring, we had "
            . number_format($s['grandTotal']) . " job vacancies with " . number_format($s['localTotal'])
            . " ({$localPct}%) for local while " . number_format($s['overseasTotal'])
            . " or {$overseasPct}% for overseas this {$period}.";

        if (!empty($s['table2']) && ($s['table2']['total'] ?? 0) > 0) {
            $t2 = $s['table2'];
            $femalePct = $t2['total'] ? round(($t2['female'] / $t2['total']) * 100) : 0;
            $bullets[] = "On the number of applicants registered, female group had a total of "
                . number_format($t2['female']) . " or {$femalePct}% out of " . number_format($t2['total']) . ".";
        }

        if (!empty($s['table3']) && ($s['table3']['ref']['total'] ?? 0) > 0) {
            $t3 = $s['table3'];
            $rate = $t3['placementRate'] ?? 0;
            $bullets[] = "Likewise, in the data of referred and placed, " . number_format($t3['placed']['total'])
                . " out of " . number_format($t3['ref']['total'])
                . " applicants were placed (placement rate: {$rate}%). "
                . "Of those placed, " . number_format($t3['placedLocal']['total'])
                . " were local and " . number_format($t3['placedOverseas']['total']) . " were overseas.";
        }

        $topPositions = $s['topPositions'] ?? [];
        if (!empty($topPositions)) {
            $names = implode(', ', array_slice(array_column($topPositions, 'name'), 0, 3));
            $bullets[] = "As presented in Table 4, the top solicited positions were {$names}, "
                . "indicating where employer demand was concentrated this {$period}.";
        }

        $lmiCount = $s['lmiInstitutions'] ?? 0;
        if ($lmiCount > 0) {
            $bullets[] = "In our Labor Market Information, we had " . number_format($lmiCount)
                . " institutions reached from various sectors of public, private and academe.";
        }

        return $bullets;
    }

    /* ────────────────────────────────────────────────────────────
       Generic style helpers
       ──────────────────────────────────────────────────────────── */

    private function applyStyle($sheet, $range, array $opts): void
    {
        $style = $sheet->getStyle($range);
        if (isset($opts['font'])) {
            $f = $style->getFont();
            if (isset($opts['font']['bold']))      $f->setBold($opts['font']['bold']);
            if (isset($opts['font']['italic']))    $f->setItalic($opts['font']['italic']);
            if (isset($opts['font']['size']))      $f->setSize($opts['font']['size']);
            if (isset($opts['font']['underline'])) $f->setUnderline($opts['font']['underline']);
            if (isset($opts['font']['color']))     $f->getColor()->setRGB($opts['font']['color']);
        }
        if (isset($opts['alignment'])) {
            $a = $style->getAlignment();
            if (isset($opts['alignment']['horizontal'])) $a->setHorizontal($opts['alignment']['horizontal']);
            if (isset($opts['alignment']['vertical']))   $a->setVertical($opts['alignment']['vertical']);
            if (isset($opts['alignment']['wrap']))       $a->setWrapText($opts['alignment']['wrap']);
        }
        if (isset($opts['fill'])) {
            $style->getFill()
                ->setFillType($opts['fill']['type'])
                ->getStartColor()->setRGB($opts['fill']['color']);
        }
    }

    private function applyHeaderStyle($sheet, string $range): void
    {
        $style = $sheet->getStyle($range);
        $style->getFont()->setBold(true)->setSize(self::FONT_SIZE);
        $style->getFill()->setFillType(Fill::FILL_SOLID)->getStartColor()->setRGB(self::HEADER_FILL);
        $style->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER)->setVertical(Alignment::VERTICAL_CENTER)->setWrapText(true);
        // Inner gridlines: hair-thin (matches stephen template)
        $style->getBorders()->getAllBorders()
            ->setBorderStyle(Border::BORDER_HAIR)
            ->getColor()->setRGB('000000');
    }

    /**
     * Inner gridlines for cells: hair-thin (the dotted-looking style in stephen template).
     */
    private function applyBorders($sheet, string $range): void
    {
        $sheet->getStyle($range)->getBorders()->getAllBorders()
            ->setBorderStyle(Border::BORDER_HAIR)
            ->getColor()->setRGB('000000');
    }

    /**
     * Draw a thin outer perimeter around a table range, leaving the inner
     * gridlines (already painted via applyBorders/applyHeaderStyle) untouched.
     */
    private function applyOuterBorder($sheet, string $range): void
    {
        $borders = $sheet->getStyle($range)->getBorders();
        $borders->getOutline()
            ->setBorderStyle(Border::BORDER_THIN)
            ->getColor()->setRGB('000000');
    }
}
