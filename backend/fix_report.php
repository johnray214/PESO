<?php
$file = 'd:/Practice/PESO/backend/app/Http/Controllers/Api/Admin/AdminReportController.php';
$content = file_get_contents($file);

$content = str_replace('use App\Models\Feedback;', 'use App\Models\LegsFeedback;', $content);

$content = str_replace('$query = Feedback::query();', '$query = LegsFeedback::query();', $content);
$content = str_replace("where('rating', (int) \$filters['rating'])", "where('rating_overall', (int) \$filters['rating'])", $content);
$content = preg_replace("/if \(!empty\(\\\$filters\['submittedBy'\]\)\)\s+\\\$query->where\('submitter_type', \\\$filters\['submittedBy'\]\);/", "", $content);

$content = str_replace("'name'     => \$fb->submitter_name,", "'name'     => trim(\$fb->first_name . ' ' . \$fb->last_name),", $content);
$content = str_replace("'type'     => \$fb->submitter_type,", "'type'     => 'Participant',", $content);
$content = str_replace("'rating'   => \$fb->rating,", "'rating'   => \$fb->rating_overall,", $content);
$content = str_replace("'comment'  => \$fb->comment,", "'comment'  => \$fb->remarks,", $content);
$content = str_replace("'category' => \$fb->category", "'category' => \$fb->program", $content);

file_put_contents($file, $content);
echo "Fixed AdminReportController successfully.\n";
