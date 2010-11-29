package MultiCheckbox::Plugin;

use strict;
use MT::Util qw( dirify );
use Text::ParseWords;

sub _find_label {
    my ($search_for,$options_val) = @_;
    my @options = quotewords(',' => 0, $options_val);
    foreach (@options) {
        my ($label,$value);
        if ($_ =~ /=/) {
            ($value,$label) = split(/=/,$_);
        } else {
            $value = $label = $_;
        }
        if ($search_for eq $value) {
            return $label;
        }
    }
    return $search_for;
}

sub load_tags {
    my $tags = {};
    # Grab the field definitions, then use those definitions to load the
    # appropriate objects. Finally, turn those into a block tag.
    my @field_defs = MT->model('field')->load({
        type => 'multi_checkbox',
    });
    foreach my $field_def (@field_defs) {
        my $tag = $field_def->tag;
        # Load the objects (entry, author, whatever) based on the current
        # field definition.
        my $obj_type = $field_def->obj_type;
        my $basename = 'field.' . $field_def->basename;
        # Create the actual tag Use the tag name and append "Loop" to it.
        $tags->{block}->{$tag . 'Loop'} = sub {
            my ( $ctx, $args, $cond ) = @_;
            # Use the $obj_type to figure out what context we're in.
            my $obj        = $ctx->stash($obj_type);
            my $out        = '';
            my $vars       = $ctx->{__stash}{vars};
            my $count      = 0;
            my $obj_value  = $obj->meta($basename);
            my @values     = split(/,/,$obj_value);
            foreach my $value (@values) {
                local $vars->{'__first__'}    = ($count == 0);
                local $vars->{'__last__'}     = ($count == scalar @values);
                local $vars->{'__label__'}    = _find_label($value,$field_def->options);
                local $vars->{'__value__'}    = $value;
                defined( $out .= $ctx->slurp( $args, $cond ) ) or return;
                $count++;
            }
            return $out;
        };
    }
    return $tags;
}

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
                my $options_val = $tmpl_param->{options};
                my @options = quotewords(',' => 0, $options_val);
                my @loop;
                my $current = $tmpl_param->{value};
                my @current_a = split(',',$current);
                foreach my $field (@options) {
                    my ($label,$value);
                    if ($field =~ /=/) {
                      ($value,$label) = split(/=/,$field);
                    } else {
                      $value = $label = $field;
                    }
                    push @loop, {
                        'label'         => $label,
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
