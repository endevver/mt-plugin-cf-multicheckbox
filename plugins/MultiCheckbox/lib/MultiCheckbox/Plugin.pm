package MultiCheckbox::Plugin;

use strict;
use MT::Util qw( dirify );

sub load_customfield_types {
    return {
        multi_checkbox => {
            label => 'Checkbox (Multi)',
            field_html => q{
<script type="text/javascript">
$(document).ready( function() {
  $('.<mt:var name="field_id">-values').change( function() {
    var v = '';
    $('.<mt:var name="field_id">-values:checked').each( function() {
      if (v != '') v += ',';
      v += $(this).val();
    });
    $('#<mt:var name="field_id">-value').val( v );
  });
});
</script>
<input id="<mt:var name="field_id">-value" name="<mt:var name="field_name">" type="hidden" value="<mt:var name="value">" />
<input type="hidden" name="<mt:var name="field_name">_cb_beacon" value="" />
<mt:loop name="values_loop">
<label style="padding-right: 20px;"><input type="checkbox" class="<mt:var name="field_name">-values" value="<mt:var name="value" encode_html="1">" <mt:if name="selected">checked="checked"</mt:if> /> <mt:var name="label"></label>
</mt:loop>
            },
            field_html_params => sub {
                my ($key, $tmpl_key, $tmpl_param) = @_;
                my $options = $tmpl_param->{options};
                my @loop;
                my $current = $tmpl_param->{value};
                my @current_a = split(',',$current);
                foreach my $value (split(',',$options)) {
                    push @loop, {
                        'label'         => $value,
                        'value'         => $value,
                        'selected'      => _value_in_array($value,\@current_a),
                    };
                }
                $tmpl_param->{values_loop} = \@loop;
            },
            options_field => q{
<input type="text" class="full-width" name="options" value="<mt:var name="options" encode_html="1">" />
            },
          no_default => 1,
          order => 500,
          column_def => 'vchar',
        }
    };
}

sub _value_in_array {
    my ($v,$a) = @_;
    foreach (@$a) {
        return 1 if $v eq $_;
    }
    return 0;
}

1;
__END__
