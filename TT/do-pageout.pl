#! /usr/bin/perl -w

sub do_pageout {
    my 
    if (%pageoutdata) { # send result to pageout
        $pageoutdata{'vendor_assign_id'} = $POL::exercise;
        $pageoutdata{'assign_probs'} = [ $POL::problem_num ];
        $pageoutdata{'student_score'} =[ '1' ];
        &send_to_pageout(%pageoutdata);
    }
