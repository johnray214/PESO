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
        $sheet->setTitle('LMA ' . $s['period']);

        // ── Column widths ──
        $sheet->getColumnDimension('A')->setWidth(6);
        $sheet->getColumnDimension('B')->setWidth(32);
        $sheet->getColumnDimension('C')->setWidth(8);
        $sheet->getColumnDimension('D')->setWidth(14);
        $sheet->getColumnDimension('E')->setWidth(14);
        $sheet->getColumnDimension('F')->setWidth(14);
        $sheet->getColumnDimension('G')->setWidth(14);
        $sheet->getColumnDimension('H')->setWidth(12);
        $sheet->getColumnDimension('I')->setWidth(12);

        $row = 1;

        // ── Title ──
        $sheet->setCellValue("A{$row}", "Labor Market Analysis: {$s['period']}");
        $sheet->mergeCells("A{$row}:I{$row}");
        $this->applyStyle($sheet, "A{$row}", [
            'font'      => ['bold' => true, 'size' => 14],
            'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER],
        ]);
        $row++;

        $sheet->setCellValue("A{$row}", 'PESO SANTIAGO CITY');
        $sheet->mergeCells("A{$row}:I{$row}");
        $this->applyStyle($sheet, "A{$row}", [
            'font'      => ['bold' => true, 'size' => 11],
            'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER],
        ]);
        $row += 2;

        // ── Section II header ──
        $sheet->setCellValue("A{$row}", 'II. PUBLIC EMPLOYMENT SERVICES THROUGH PESO/PEIS');
        $sheet->mergeCells("A{$row}:I{$row}");
        $this->applyStyle($sheet, "A{$row}", ['font' => ['bold' => true]]);
        $row++;

        $localPct    = $s['grandTotal'] > 0 ? round(($s['localTotal']    / $s['grandTotal']) * 100) : 0;
        $overseasPct = $s['grandTotal'] > 0 ? round(($s['overseasTotal'] / $s['grandTotal']) * 100) : 0;

        $introText = "A total of " . number_format($s['grandTotal']) . " job vacancies were solicited and promoted to our jobseekers. "
            . "Table 1 shows that majority of job vacancies solicited were from local employment, "
            . "with a total of " . number_format($s['localTotal']) . " or {$localPct}%.";

        $sheet->setCellValue("A{$row}", $introText);
        $sheet->mergeCells("A{$row}:I{$row}");
        $sheet->getRowDimension($row)->setRowHeight(30);
        $sheet->getStyle("A{$row}")->getAlignment()->setWrapText(true);
        $row += 2;

        // ── TABLE 1 ──
        $sheet->setCellValue("A{$row}", 'Table 1. Job vacancies solicited');
        $sheet->mergeCells("A{$row}:I{$row}");
        $this->applyStyle($sheet, "A{$row}", ['font' => ['bold' => true, 'italic' => true]]);
        $row++;

        // Table 1 headers
        $sheet->setCellValue("A{$row}", 'Nature of Vacancy');
        $sheet->mergeCells("A{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", 'No. of Vacancies Solicited');
        $sheet->mergeCells("D{$row}:F{$row}");
        $sheet->setCellValue("G{$row}", 'Percentage');
        $sheet->mergeCells("G{$row}:I{$row}");
        $this->applyHeaderStyle($sheet, "A{$row}:I{$row}");
        $row++;

        // Local row
        $sheet->setCellValue("A{$row}", 'Local');
        $sheet->mergeCells("A{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", $s['localTotal']);
        $sheet->mergeCells("D{$row}:F{$row}");
        $localFrac = $s['grandTotal'] > 0 ? $s['localTotal'] / $s['grandTotal'] : 0;
        $sheet->setCellValue("G{$row}", $localFrac);
        $sheet->mergeCells("G{$row}:I{$row}");
        $sheet->getStyle("G{$row}")->getNumberFormat()->setFormatCode('0.00%');
        $sheet->getStyle("D{$row}")->getNumberFormat()->setFormatCode('#,##0');
        $row++;

        // Overseas row
        $sheet->setCellValue("A{$row}", 'Overseas');
        $sheet->mergeCells("A{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", $s['overseasTotal']);
        $sheet->mergeCells("D{$row}:F{$row}");
        $overseasFrac = $s['grandTotal'] > 0 ? $s['overseasTotal'] / $s['grandTotal'] : 0;
        $sheet->setCellValue("G{$row}", $overseasFrac);
        $sheet->mergeCells("G{$row}:I{$row}");
        $sheet->getStyle("G{$row}")->getNumberFormat()->setFormatCode('0.00%');
        $sheet->getStyle("D{$row}")->getNumberFormat()->setFormatCode('#,##0');
        $row++;

        // Total row
        $sheet->setCellValue("A{$row}", 'Total');
        $sheet->mergeCells("A{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", $s['grandTotal']);
        $sheet->mergeCells("D{$row}:F{$row}");
        $sheet->setCellValue("G{$row}", 1.0);
        $sheet->mergeCells("G{$row}:I{$row}");
        $sheet->getStyle("G{$row}")->getNumberFormat()->setFormatCode('0.00%');
        $sheet->getStyle("D{$row}")->getNumberFormat()->setFormatCode('#,##0');
        $this->applyStyle($sheet, "A{$row}:I{$row}", ['font' => ['bold' => true], 'fill' => ['type' => Fill::FILL_SOLID, 'color' => 'F8FAFC']]);
        $row += 2;

        // ── TABLE 4 ──
        $sheet->setCellValue("A{$row}", 'Table 4. Top Commonly Solicited Job Vacancies for Local and Overseas Employment');
        $sheet->mergeCells("A{$row}:I{$row}");
        $this->applyStyle($sheet, "A{$row}", ['font' => ['bold' => true, 'italic' => true]]);
        $row++;

        // Table 4 sub-header
        $sheet->setCellValue("A{$row}", '');
        $sheet->setCellValue("B{$row}", 'Position');
        $sheet->setCellValue("C{$row}", '');
        $sheet->setCellValue("D{$row}", 'Local');
        $sheet->setCellValue("E{$row}", 'Overseas');
        $sheet->setCellValue("F{$row}", 'Total');
        $sheet->setCellValue("G{$row}", 'Type of Industries');
        $sheet->mergeCells("G{$row}:H{$row}");
        $sheet->setCellValue("I{$row}", 'Percentage');
        $this->applyHeaderStyle($sheet, "A{$row}:I{$row}");
        $row++;

        $positions   = $s['topPositions'] ?? [];
        $grandTotal  = $s['grandTotal'];
        $top5End     = min(5, count($positions));

        foreach ($positions as $idx => $pos) {
            $num = $idx + 1;
            $sheet->setCellValue("A{$row}", $num);
            $sheet->setCellValue("B{$row}", $pos['name']);
            $sheet->setCellValue("D{$row}", $pos['local']);
            $sheet->setCellValue("E{$row}", $pos['overseas']);
            $sheet->setCellValue("F{$row}", $pos['total']);
            $sheet->setCellValue("G{$row}", $pos['industry'] ?? '');
            $sheet->mergeCells("G{$row}:H{$row}");
            $pct = $grandTotal > 0 ? $pos['total'] / $grandTotal : 0;
            $sheet->setCellValue("I{$row}", $pct);
            $sheet->getStyle("I{$row}")->getNumberFormat()->setFormatCode('0.0000');
            foreach (['D','E','F'] as $col) {
                $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('#,##0');
            }
            if ($idx < 5) {
                $this->applyStyle($sheet, "A{$row}:I{$row}", ['fill' => ['type' => Fill::FILL_SOLID, 'color' => 'FAFAFF']]);
            }
            // Subtotal after top 5
            if ($idx === 4) {
                $row++;
                $top5Local    = array_sum(array_column(array_slice($positions, 0, 5), 'local'));
                $top5Overseas = array_sum(array_column(array_slice($positions, 0, 5), 'overseas'));
                $top5Total    = array_sum(array_column(array_slice($positions, 0, 5), 'total'));
                $sheet->setCellValue("B{$row}", 'Subtotal - Top 5');
                $sheet->setCellValue("D{$row}", $top5Local);
                $sheet->setCellValue("E{$row}", $top5Overseas);
                $sheet->setCellValue("F{$row}", $top5Total);
                $pct5 = $grandTotal > 0 ? $top5Total / $grandTotal : 0;
                $sheet->setCellValue("I{$row}", $pct5);
                $sheet->getStyle("I{$row}")->getNumberFormat()->setFormatCode('0.0000');
                foreach (['D','E','F'] as $col) {
                    $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('#,##0');
                }
                $this->applyStyle($sheet, "A{$row}:I{$row}", ['font' => ['bold' => true], 'fill' => ['type' => Fill::FILL_SOLID, 'color' => 'EDE9FE']]);
                $row++;
                $sheet->setCellValue("A{$row}", 'Top 6 and below');
                $sheet->mergeCells("A{$row}:I{$row}");
                $this->applyStyle($sheet, "A{$row}", ['font' => ['bold' => true]]);
            }
            $row++;
        }

        // Others row
        if (!empty($s['others'])) {
            $others = $s['others'];
            $sheet->setCellValue("B{$row}", 'Others: ' . ($others['names'] ?? ''));
            $sheet->mergeCells("B{$row}:C{$row}");
            $sheet->setCellValue("D{$row}", $others['local'] ?? 0);
            $sheet->setCellValue("E{$row}", $others['overseas'] ?? 0);
            $sheet->setCellValue("F{$row}", $others['total'] ?? 0);
            $othersPct = $grandTotal > 0 ? (($others['total'] ?? 0) / $grandTotal) : 0;
            $sheet->setCellValue("I{$row}", $othersPct);
            $sheet->getStyle("I{$row}")->getNumberFormat()->setFormatCode('0.0000');
            foreach (['D','E','F'] as $col) {
                $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('#,##0');
            }
            $row++;
        }

        // Grand Total row
        $sheet->setCellValue("A{$row}", 'Grand Total');
        $sheet->mergeCells("A{$row}:C{$row}");
        $sheet->setCellValue("D{$row}", $s['localTotal']);
        $sheet->setCellValue("E{$row}", $s['overseasTotal']);
        $sheet->setCellValue("F{$row}", $s['grandTotal']);
        $sheet->setCellValue("I{$row}", 1.0);
        $sheet->getStyle("I{$row}")->getNumberFormat()->setFormatCode('0.0000');
        foreach (['D','E','F'] as $col) {
            $sheet->getStyle("{$col}{$row}")->getNumberFormat()->setFormatCode('#,##0');
        }
        $this->applyStyle($sheet, "A{$row}:I{$row}", [
            'font' => ['bold' => true],
            'fill' => ['type' => Fill::FILL_SOLID, 'color' => 'F8FAFC'],
        ]);
        $row += 2;

        // ── TABLE 5 LMI ──
        $sheet->setCellValue("A{$row}", 'III. LABOR MARKET INFORMATION');
        $sheet->mergeCells("A{$row}:I{$row}");
        $this->applyStyle($sheet, "A{$row}", ['font' => ['bold' => true]]);
        $row++;

        $lmiCount = $s['lmiInstitutions'] ?? 0;
        $lmiText  = "In our Labor Market Information (LMI), we have reached individuals through the participation of "
            . number_format($lmiCount) . " institutions from various sectors in the private, public and academe.";
        $sheet->setCellValue("A{$row}", $lmiText);
        $sheet->mergeCells("A{$row}:I{$row}");
        $sheet->getRowDimension($row)->setRowHeight(30);
        $sheet->getStyle("A{$row}")->getAlignment()->setWrapText(true);
        $row++;

        $sheet->setCellValue("A{$row}", 'Table 5. Individual and Institutions Reached');
        $sheet->mergeCells("A{$row}:I{$row}");
        $this->applyStyle($sheet, "A{$row}", ['font' => ['bold' => true, 'italic' => true]]);
        $row++;

        // Table 5 headers
        $sheet->setCellValue("A{$row}", 'Institutions Reached');
        $sheet->mergeCells("A{$row}:B{$row}");
        $sheet->setCellValue("C{$row}", 'Type of LMI');
        $sheet->mergeCells("C{$row}:I{$row}");
        $this->applyHeaderStyle($sheet, "A{$row}:I{$row}");
        $row++;

        $sheet->setCellValue("A{$row}", 'No.');
        $sheet->setCellValue("B{$row}", 'Partner Agencies');
        $sheet->setCellValue("C{$row}", 'LMI Type');
        $sheet->mergeCells("C{$row}:I{$row}");
        $this->applyHeaderStyle($sheet, "A{$row}:I{$row}");
        $row++;

        $lmiBreakdown = $s['lmiBreakdown'] ?? [];
        if (empty($lmiBreakdown)) {
            $lmiBreakdown = [['count' => $lmiCount, 'type' => 'Public & Private Agencies', 'lmiType' => 'Others-Job Posting']];
        }
        foreach ($lmiBreakdown as $lmi) {
            $sheet->setCellValue("A{$row}", $lmi['count'] ?? 0);
            $sheet->setCellValue("B{$row}", $lmi['type']    ?? '');
            $sheet->setCellValue("C{$row}", $lmi['lmiType'] ?? '');
            $sheet->mergeCells("C{$row}:I{$row}");
            $row++;
        }
        // Total row
        $sheet->setCellValue("A{$row}", $lmiCount);
        $sheet->setCellValue("B{$row}", 'TOTAL');
        $sheet->mergeCells("B{$row}:I{$row}");
        $this->applyStyle($sheet, "A{$row}:I{$row}", [
            'font' => ['bold' => true],
            'fill' => ['type' => Fill::FILL_SOLID, 'color' => 'F8FAFC'],
        ]);
        $row += 2;

        // ── Signatures ──
        $sheet->setCellValue("A{$row}", 'Reviewed by:');
        $sheet->setCellValue("F{$row}", 'Noted:');
        $row += 3;
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

    /* ── Style helpers ── */

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
        $style->getFont()->setBold(true)->setSize(10);
        $style->getFill()->setFillType(Fill::FILL_SOLID)->getStartColor()->setRGB('EDE9FE');
        $style->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        $style->getBorders()->getBottom()->setBorderStyle(Border::BORDER_THIN)->getColor()->setRGB('A78BFA');
    }
}